const MaxArrayLength = 32
const MaxInputLength = 34

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 0xFF'u64)
    bits = bits shr 8

proc get_products_of_all_other_elements*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "get_products_of_all_other_elements".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  if input[0] < 0 or input[0] > MaxArrayLength: return -1
  let n = int(input[0])
  if length != csize_t(n + 1): return -1
  var result: array[MaxArrayLength, int64]
  for i in 0 ..< n:
    if input[i + 1] < -2 or input[i + 1] > 2: return -1
  if n < 2: return 0
  let outputBytes = n * 8
  if output == nil or capacity < csize_t(outputBytes): return -2

  result[0] = 1
  for i in 0 ..< n - 1: result[i + 1] = input[i + 1] * result[i]
  var suffix = 1'i64
  for i in countdown(n - 1, 1):
    let value = input[i + 1]
    result[i - 1] *= suffix * value
    suffix *= value
  for i in 0 ..< n: writeI64Le(output, i * 8, result[i])
  int64(outputBytes)
