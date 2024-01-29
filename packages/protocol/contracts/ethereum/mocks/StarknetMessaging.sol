// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import './IStarknetMessaging.sol';
import './NamedStorage.sol';

// Implements sending messages to L2 by adding them to a pipe and consuming messages from L2 by
// removing them from a different pipe. A deriving contract can handle the former pipe and add items
// to the latter pipe while interacting with L2.
contract StarknetMessaging is IStarknetMessaging {
    // Random slot storage elements and accessors
    string constant L1L2_MESSAGE_MAP_TAG = 'STARKNET_1.0_MSGING_L1TOL2_MAPPING_V2';
    string constant L2L1_MESSAGE_MAP_TAG = 'STARKNET_1.0_MSGING_L2TOL1_MAPPING';

    string constant L1L2_MESSAGE_NONCE_TAG = 'STARKNET_1.0_MSGING_L1TOL2_NONCE';

    uint256 public constant MAX_L1_MSG_FEE = 1 ether;

    function l1ToL2Messages(bytes32 msgHash) external view returns (uint256) {
        return l1ToL2Messages()[msgHash];
    }

    function l2ToL1Messages(bytes32 msgHash) external view returns (uint256) {
        return l2ToL1Messages()[msgHash];
    }

    function l1ToL2Messages() internal pure returns (mapping(bytes32 => uint256) storage) {
        return NamedStorage.bytes32ToUint256Mapping(L1L2_MESSAGE_MAP_TAG);
    }

    function l2ToL1Messages() internal pure returns (mapping(bytes32 => uint256) storage) {
        return NamedStorage.bytes32ToUint256Mapping(L2L1_MESSAGE_MAP_TAG);
    }

    function l1ToL2MessageNonce() public view returns (uint256) {
        return NamedStorage.getUintValue(L1L2_MESSAGE_NONCE_TAG);
    }

    /// @notice Sends a message to an L2 contract
    function sendMessageToL2(uint256 toAddress, uint256 selector, uint256[] calldata payload) external payable override returns (bytes32, uint256) {
        require(msg.value <= MAX_L1_MSG_FEE, 'MAX_L1_MSG_FEE_EXCEEDED');
        uint256 nonce = l1ToL2MessageNonce();
        NamedStorage.setUintValue(L1L2_MESSAGE_NONCE_TAG, nonce + 1);
        emit LogMessageToL2(msg.sender, toAddress, selector, payload, nonce, msg.value);
        bytes32 msgHash = keccak256(abi.encodePacked(uint256(uint160(address(msg.sender))), toAddress, nonce, selector, payload.length, payload));
        // Note that the inclusion of the unique nonce in the message hash implies that
        // l1ToL2Messages()[msgHash] was not accessed before.
        l1ToL2Messages()[msgHash] = msg.value + 1;
        return (msgHash, nonce);
    }

    /// @notice Consumes a message that was sent from an L2 contract and returns the hash of the message
    function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload) external override returns (bytes32) {
        bytes32 msgHash = keccak256(abi.encodePacked(fromAddress, uint256(uint160(msg.sender)), payload.length, payload));

        require(l2ToL1Messages()[msgHash] > 0, 'INVALID_MESSAGE_TO_CONSUME');
        emit ConsumedMessageToL1(fromAddress, msg.sender, payload);
        l2ToL1Messages()[msgHash] -= 1;
        return msgHash;
    }
}
