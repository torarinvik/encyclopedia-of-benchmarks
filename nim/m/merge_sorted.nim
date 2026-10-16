const
  MaxArrayLength = 64
  MaxInputLength = 2 + 2 * MaxArrayLength
  MaxParseableInputLength = MaxInputLength + 1
  MinValue = -1_000_000'i64
  MaxValue = 1_000_000'i64
  ChecksumOffset = 1_000_001'i64

proc merge_sorted*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "merge_sorted".} =
  if values.isNil or length < 2 or length > csize_t(MaxParseableInputLength): return -1
  if values[0] < 0 or values[0] > MaxArrayLength or
      values[1] < 0 or values[1] > MaxArrayLength: return -1

  let leftCount = int(values[0])
  let rightCount = int(values[1])
  if length != csize_t(2 + leftCount + rightCount): return -1
  let rightStart = 2 + leftCount

  for index in 0 ..< leftCount:
    let value = values[2 + index]
    if value < MinValue or value > MaxValue or
        (index > 0 and values[2 + index - 1] > value): return -1
  for index in 0 ..< rightCount:
    let value = values[rightStart + index]
    if value < MinValue or value > MaxValue or
        (index > 0 and values[rightStart + index - 1] > value): return -1

  var leftIndex = 0
  var rightIndex = 0
  var outputIndex = 0'i64
  var checksum = 0'i64
  while leftIndex < leftCount and rightIndex < rightCount:
    var value: int64
    if values[2 + leftIndex] <= values[rightStart + rightIndex]:
      value = values[2 + leftIndex]
      inc leftIndex
    else:
      value = values[rightStart + rightIndex]
      inc rightIndex
    checksum += (outputIndex + 1) * (value + ChecksumOffset)
    inc outputIndex
  while leftIndex < leftCount:
    let value = values[2 + leftIndex]
    checksum += (outputIndex + 1) * (value + ChecksumOffset)
    inc leftIndex
    inc outputIndex
  while rightIndex < rightCount:
    let value = values[rightStart + rightIndex]
    checksum += (outputIndex + 1) * (value + ChecksumOffset)
    inc rightIndex
    inc outputIndex
  checksum
