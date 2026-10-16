const MaxArrayLength = 64
const MaxInputLength = 67

proc searchSegment(input: ptr UncheckedArray[int64], begin, length: int,
                   target: int64, offset: int): int64 =
  if length == 0: return -1
  let first = input[begin]
  let last = input[begin + length - 1]
  if target < first or target > last: return -1
  if first == last:
    return if target == first: int64(offset) else: -1

  let interpolation = (length - 1) * int(target - first) div int(last - first)
  let midpoint = length div 2
  let left = min(interpolation, midpoint)
  let right = max(interpolation, midpoint)
  var fromIndex, toIndex: int
  if target < input[begin + left]:
    if left == 0: return -1
    fromIndex = 0
    toIndex = left - 1
  elif target < input[begin + right]:
    fromIndex = left
    toIndex = right - 1
  else:
    fromIndex = right
    toIndex = length - 1
  if toIndex < fromIndex: return -1
  searchSegment(input, begin + fromIndex, toIndex - fromIndex + 1,
                target, offset + fromIndex)

proc fast_searcher*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "fast_searcher".} =
  if input.isNil or length < 2 or length > MaxInputLength: return -2
  let countValue = input[0]
  if countValue < 0 or countValue > MaxArrayLength: return -2
  let count = int(countValue)
  if int(length) != count + 2: return -2
  for index in 0 ..< count:
    let value = input[1 + index]
    if value < -1000 or value > 1000: return -2
    if index > 0 and input[index] >= value: return -2
  let target = input[int(length) - 1]
  if target < -1000 or target > 1000: return -2
  searchSegment(input, 1, count, target, 0)
