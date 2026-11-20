type
  I64Input = ptr UncheckedArray[int64]
  Search = object
    capacity: int
    count: int
    requests: array[64, int]
    nextAfter: array[1024, int]
    nextPosition: array[16, int]

const MaxInputLength = 67
const PageCount = 16
const ChecksumRadix = 33_281'i64

proc belady_optimal_paging*(input: I64Input, length: csize_t): int64 {.cdecl, exportc: "belady_optimal_paging".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let capacityValue = input[0]
  let countValue = input[1]
  if capacityValue < 1 or capacityValue > 8 or countValue < 0 or countValue > 64:
    return -1
  if length != csize_t(2 + countValue): return -1
  var state = Search(capacity: int(capacityValue), count: int(countValue))
  for time in 0 ..< state.count:
    if input[csize_t(2 + time)] < 0 or input[csize_t(2 + time)] >= PageCount: return -1
    state.requests[time] = int(input[csize_t(2 + time)])
  for page in 0 ..< PageCount: state.nextPosition[page] = state.count
  var reverseTime = state.count
  while reverseTime > 0:
    dec reverseTime
    for page in 0 ..< PageCount:
      state.nextAfter[reverseTime * PageCount + page] = state.nextPosition[page]
    state.nextPosition[state.requests[reverseTime]] = reverseTime

  var resident: array[PageCount, bool]
  var residentCount = 0
  var misses = 0'i64
  var evictionChecksum = 0'i64
  for time in 0 ..< state.count:
    let requested = state.requests[time]
    if resident[requested]: continue
    inc misses
    if residentCount == state.capacity:
      var victim = -1
      var farthest = -1
      for page in 0 ..< PageCount:
        if resident[page] and state.nextAfter[time * PageCount + page] > farthest:
          victim = page
          farthest = state.nextAfter[time * PageCount + page]
      resident[victim] = false
      dec residentCount
      evictionChecksum += int64((time + 1) * (victim + 1))
    resident[requested] = true
    inc residentCount
  misses * ChecksumRadix + evictionChecksum
