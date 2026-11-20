const MaxN = 64
const MaxInput = 67
const MaxSegments = 65

proc gcdNonnegative(a0, b0: int64): int64 =
  var a = a0
  var b = b0
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc combineValue(mode, a, b: int64): int64 =
  if mode == 0: return gcdNonnegative(a, b)
  if mode == 1: return a or b
  a and b

proc distinct_subarray_aggregates*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "distinct_subarray_aggregates".} =
  if input == nil or length < 2 or length > csize_t(MaxInput): return -1
  let mode = input[0]
  let nValue = input[1]
  if mode < 0 or mode > 2 or nValue < 0 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != 2 + n: return -1

  var segmentValue, segmentLeft, segmentRight: array[MaxSegments, int64]
  var segmentCount = 0
  var aggregateSum = 0'i64
  var suffixDistinctCount = 0'i64
  for right in 0 ..< n:
    let value = input[2 + right]
    if value < 0 or value > 255: return -1
    for j in 0 ..< segmentCount:
      segmentValue[j] = combineValue(mode, segmentValue[j], value)
    segmentValue[segmentCount] = value
    segmentLeft[segmentCount] = int64(right)
    segmentRight[segmentCount] = int64(right)
    inc segmentCount

    var write = 0
    for read in 0 ..< segmentCount:
      if write > 0 and segmentValue[read] == segmentValue[write - 1]:
        segmentRight[write - 1] = segmentRight[read]
      else:
        segmentValue[write] = segmentValue[read]
        segmentLeft[write] = segmentLeft[read]
        segmentRight[write] = segmentRight[read]
        inc write
    segmentCount = write
    suffixDistinctCount += int64(segmentCount)
    for j in 0 ..< segmentCount:
      aggregateSum += segmentValue[j] * (segmentRight[j] - segmentLeft[j] + 1)
  aggregateSum * 1024 + suffixDistinctCount
