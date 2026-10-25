const MaxN = 64
const MaxStride = 4
const MaxPhysicalN = 1 + (MaxN - 1) * MaxStride
const MaxInputLength = 2 + MaxPhysicalN
const MaxValue = 1_000_000'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc tsvc_s318_strided_absolute_maximum_with_index*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s318_strided_absolute_maximum_with_index".} =
  if input == nil or length < 3 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let strideValue = input[1]
  if nValue < 1 or nValue > MaxN or strideValue < 1 or strideValue > MaxStride: return -1
  let n = int(nValue)
  let stride = int(strideValue)
  let physicalN = 1 + (n - 1) * stride
  if int(length) != 2 + physicalN: return -1
  for i in 0 ..< physicalN:
    if input[i + 2] < -MaxValue or input[i + 2] > MaxValue: return -1
  if output == nil or outputCapacity < 16: return -2

  var maximum = abs(input[2])
  var maximumIndex = 0
  for i in 1 ..< n:
    let magnitude = abs(input[2 + i * stride])
    if magnitude > maximum:
      maximum = magnitude
      maximumIndex = i
  storeI64Le(output, 0, maximum)
  storeI64Le(output, 8, int64(maximumIndex))
  2
