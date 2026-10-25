const MaxN = 64
const MaxInputLength = 2 + 3 * MaxN
const MaxValue = 1_000_000'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc boundedValue(value: int64): bool =
  value >= -MaxValue and value <= MaxValue

proc tsvc_s132_shifted_row_update*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s132_shifted_row_update".} =
  if input == nil or length < 8 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 2 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != 2 + 3 * n: return -1

  let rowStart = 1
  let targetStart = rowStart + n
  let bStart = targetStart + n
  let c1Index = bStart + n
  var target: array[MaxN, int64]
  for i in 0 ..< n:
    target[i] = input[targetStart + i]
    if not boundedValue(input[rowStart + i]) or not boundedValue(target[i]) or
        not boundedValue(input[bStart + i]): return -1
  let c1 = input[c1Index]
  if not boundedValue(c1): return -1
  if output == nil or outputCapacity < csize_t(8 * n): return -2

  for i in 1 ..< n:
    target[i] = input[rowStart + i - 1] + input[bStart + i] * c1
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, target[i])
  int64(n)
