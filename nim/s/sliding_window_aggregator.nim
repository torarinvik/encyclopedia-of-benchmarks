const MaxParseableInputLength = 259
const MaxValue = 1_000_000'i64
const InvalidResult = low(int64)

proc sliding_window_aggregator*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "sliding_window_aggregator".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxParseableInputLength):
    return InvalidResult
  if input[0] < 1'i64 or input[0] > 64'i64 or input[1] < 1'i64 or input[1] > 256'i64:
    return InvalidResult

  let capacity = int(input[0])
  let count = int(input[1])
  if length != csize_t(count + 2): return InvalidResult
  for index in 0 ..< count:
    if input[index + 2] < -MaxValue or input[index + 2] > MaxValue: return InvalidResult

  var window: array[64, int64]
  var head = 0
  var size = 0
  var total = 0'i64
  for index in 0 ..< count:
    let value = input[index + 2]
    if size < capacity:
      let tail = (head + size) mod capacity
      window[tail] = value
      total += value
      inc size
    else:
      total -= window[head]
      window[head] = value
      total += value
      head = (head + 1) mod capacity
  total
