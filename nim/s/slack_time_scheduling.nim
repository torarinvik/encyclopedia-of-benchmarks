const MaxN = 64
const MaxTime = 1_000_000'i64

proc slack_time_scheduling*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "slack_time_scheduling".} =
  if input == nil or length < 1 or length > csize_t(1 + 2 * MaxN): return -1
  if input[0] < 0 or input[0] > MaxN: return -1
  let n = int(input[0])
  if length != csize_t(1 + 2 * n): return -1
  var slack: array[MaxN, int64]
  var order: array[MaxN, int]
  for i in 0 ..< n:
    let execution = input[1 + 2 * i]
    let deadline = input[2 + 2 * i]
    if execution < 0 or execution > MaxTime or deadline < 0 or deadline > MaxTime: return -1
    slack[i] = deadline - execution
    order[i] = i
  let bytes = csize_t(8 * n)
  if output == nil or capacity < bytes: return -2
  for i in 1 ..< n:
    let key = order[i]
    var j = i
    while j > 0 and slack[key] < slack[order[j - 1]]:
      order[j] = order[j - 1]
      dec j
    order[j] = key
  for i in 0 ..< n:
    let bits = uint64(order[i])
    for byte in 0 ..< 8: output[i * 8 + byte] = uint8((bits shr (byte * 8)) and 255)
  int64(bytes)
