type I64Input = ptr UncheckedArray[int64]
const MaxInputLength = 259
const MaxDomainValue = 2_147_483_647'i64
const InvalidResult = -1'i64
proc longest_subarray_with_sum_at_most*(input: I64Input, length: csize_t): int64
    {.cdecl, exportc: "longest_subarray_with_sum_at_most".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return InvalidResult
  let target = input[0]
  let rawCount = input[1]
  if target < 0 or target > MaxDomainValue or rawCount < 0 or rawCount > 256: return InvalidResult
  let count = int(rawCount)
  if int(length) != count + 2: return InvalidResult
  for index in 0 ..< count:
    let value = input[index + 2]
    if value < 0 or value > MaxDomainValue: return InvalidResult
  var left = 0
  var bestLength = 0
  var windowSum = 0'i64
  for right in 0 ..< count:
    windowSum += input[right + 2]
    while windowSum > target and left <= right:
      windowSum -= input[left + 2]
      inc left
    let currentLength = if left <= right: right - left + 1 else: 0
    if currentLength > bestLength: bestLength = currentLength
  int64(bestLength)
