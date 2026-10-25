const MaxN = 64
const MaxInputLength = 1 + 2 * MaxN
const MaxValue = 2'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc boundedValue(value: int64): bool =
  value >= -MaxValue and value <= MaxValue

proc tsvc_s452_index_weighted_vector_map*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s452_index_weighted_vector_map".} =
  if input == nil or length < 3 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != 1 + 2 * n: return -1

  let bStart = 1
  let cStart = bStart + n
  for i in 0 ..< n:
    if not boundedValue(input[bStart + i]) or not boundedValue(input[cStart + i]): return -1
  if output == nil or outputCapacity < csize_t(8 * n): return -2

  for i in 0 ..< n:
    let indexWeight = int64(i + 1)
    let value = input[bStart + i] + input[cStart + i] * indexWeight
    storeI64Le(output, 8 * i, value)
  int64(n)
