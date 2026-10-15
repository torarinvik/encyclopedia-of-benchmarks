## Emit the one-based hexagonal number sequence as little-endian i64 values.
const MaxLength = 1024
const BytesPerValue = 8

proc storeI64Le(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< BytesPerValue:
    output[position + byte] = uint8((bits shr (byte * 8)) and 255)

proc hexagonal_numbers_one_based*(length: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "hexagonal_numbers_one_based".} =
  if length < 0 or length > MaxLength: return -1
  let n = int(length)
  let required = n * BytesPerValue
  if outputCapacity < csize_t(required) or (required > 0 and output == nil): return -2
  for index in 0 ..< n:
    let i = int64(index) + 1
    storeI64Le(output, index * BytesPerValue, i * (2 * i - 1))
  length
