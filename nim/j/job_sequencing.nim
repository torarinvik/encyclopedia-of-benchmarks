const
  MaxJobs = 32
  MaxInputLength = 1 + 3 * MaxJobs + 1
  MaxProfit = 1_000_000'i64

proc job_sequencing*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "job_sequencing".} =
  if input.isNil or length < 4 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxJobs: return -1
  let n = int(input[0])
  if length != csize_t(1 + 3 * n): return -1
  var seen: array[128, bool]
  var previousProfit = MaxProfit + 1
  for i in 0 ..< n:
    let base = 1 + 3 * i
    let ident, deadline, profit = input[base], input[base + 1], input[base + 2]
    if not ((ident >= 65 and ident <= 90) or (ident >= 97 and ident <= 122)) or seen[int(ident)] or deadline < 1 or deadline > int64(n) or profit < 1 or profit > MaxProfit or profit >= previousProfit: return -1
    seen[int(ident)] = true
    previousProfit = profit
  var slots: array[MaxJobs, uint8]
  var totalProfit = 0'i64
  for i in 0 ..< n:
    let base = 1 + 3 * i
    let deadline = int(input[base + 1])
    for remaining in countdown(deadline, 1):
      let slot = remaining - 1
      if slots[slot] == 0:
        slots[slot] = uint8(input[base])
        totalProfit += input[base + 2]
        break
  var count = 0
  for slot in 0 ..< n:
    if slots[slot] != 0:
      inc count
  let required = 9 + count
  if output.isNil or capacity < csize_t(required): return -2
  output[0] = uint8(count)
  for byte in 0 ..< 8: output[1 + byte] = uint8((uint64(totalProfit) shr (8 * byte)) and 255)
  var written = 9
  for slot in 0 ..< n:
    if slots[slot] != 0:
      output[written] = slots[slot]
      inc written
  int64(required)
