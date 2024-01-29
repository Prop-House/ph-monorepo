/**
 * Currently there is no way to pass struct types with pointers in calldata, so we must pass the 2d array as a flat array and then reconstruct the type.
 * The structure of the flat array that is output from this function is as follows:
 * flat_array[0] = num_arrays
 * flat_array[1:1+num_arrays] = offsets
 * flat_array[1+num_arrays:] = elements
 * @param array2D The 2d array to flatten
 * @returns The flattened array
 */
export const flatten2DArray = (array2D: string[][]): string[] => {
  const flatArray: string[] = [];
  const numArrays = `0x${array2D.length.toString(16)}`;
  flatArray.push(numArrays);
  flatArray.push('0x0'); // Offset of first array

  let offset = 0;
  for (let i = 0; i < array2D.length - 1; i++) {
    offset += array2D[i].length;
    flatArray.push(`0x${offset.toString(16)}`);
  }
  const elements = array2D.reduce(
    (accumulator, value) => accumulator.concat(value),
    []
  );
  return flatArray.concat(elements);
};

/**
 * Converts little endian intsequence to a string
 * @param intsArray The intsequence to convert to a string
 */
export const stringFromLE = (intsArray: string[]) => {
  let str = '';
  for (const intValue of intsArray) {
    const hexStr = BigInt(intValue).toString(16);
    const leBytes = Buffer.from(hexStr, 'hex').reverse();
    const chunk = leBytes.toString();
    str += chunk;
  }
  // If there's padding (e.g., null characters), remove them
  return str.replace(/\0/g, '');
};
