const MaxDimension = 64
const MaxInputValues = 3 + 2 * MaxDimension * MaxDimension
const MaxOutputValues = MaxDimension * MaxDimension

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc matrix_product_mod_2*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "matrix_product_mod_2".} =
  if input.isNil or length < 3 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  let mValue = input[1]
  let kValue = input[2]
  if nValue < 1 or nValue > int64(MaxDimension) or mValue < 1 or
     mValue > int64(MaxDimension) or kValue < 1 or kValue > int64(MaxDimension): return -1
  let n = int(nValue)
  let m = int(mValue)
  let k = int(kValue)
  let aLength = n * m
  let bLength = m * k
  if length != csize_t(3 + aLength + bLength): return -1

  var packedB: array[MaxDimension, uint64]
  let bStart = 3 + aLength
  for inner in 0 ..< m:
    for column in 0 ..< k:
      let bit = input[bStart + inner * k + column]
      if bit != 0 and bit != 1: return -1
      packedB[inner] = packedB[inner] or (uint64(bit) shl column)

  var staged: array[MaxOutputValues, int64]
  for row in 0 ..< n:
    var accumulator = 0'u64
    for inner in 0 ..< m:
      let bit = input[3 + row * m + inner]
      if bit != 0 and bit != 1: return -1
      if bit == 1: accumulator = accumulator xor packedB[inner]
    for column in 0 ..< k:
      staged[row * k + column] = int64((accumulator shr column) and 1)

  let required = 8 * n * k
  if output.isNil or capacity < csize_t(required): return -2
  for index in 0 ..< n * k:
    storeI64Le(output, 8 * index, staged[index])
  int64(required)
