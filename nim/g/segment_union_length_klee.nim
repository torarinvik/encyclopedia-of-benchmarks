const MaxN = 64
const MaxEvents = 128
const MaxInputLength = 130

proc siftDown(events: var array[MaxEvents, int64], rootStart, endExclusive: int) =
  var root = rootStart
  while root < endExclusive div 2:
    var child = root * 2 + 1
    if child + 1 < endExclusive and events[child] < events[child + 1]: inc child
    if events[root] >= events[child]: break
    swap(events[root], events[child])
    root = child

proc segment_union_length_klee*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "segment_union_length_klee".} =
  if input == nil or length < 1 or length > MaxInputLength: return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxN: return -1
  let n = int(nValue)
  if length != csize_t(1 + 2 * n): return -1
  var events: array[MaxEvents, int64]
  for i in 0 ..< n:
    let left = input[1 + 2 * i]
    let right = input[2 + 2 * i]
    if left < -1000 or left > right or right > 1000: return -1
    events[2 * i] = 2 * (left + 1000)
    events[2 * i + 1] = 2 * (right + 1000) + 1
  let eventCount = 2 * n
  if eventCount == 0: return 0
  for start in countdown(eventCount div 2 - 1, 0):
    siftDown(events, start, eventCount)
  var endExclusive = eventCount
  while endExclusive > 1:
    swap(events[0], events[endExclusive - 1])
    dec endExclusive
    siftDown(events, 0, endExclusive)
  var active = 0'i64
  var total = 0'i64
  var previous = 0'i64
  var index = 0
  while index < eventCount:
    let coordinateCode = events[index] div 2
    let coordinate = coordinateCode - 1000
    if index > 0 and active > 0: total += coordinate - previous
    var delta = 0'i64
    while index < eventCount and events[index] div 2 == coordinateCode:
      if events[index] mod 2 == 0: inc delta else: dec delta
      inc index
    active += delta
    previous = coordinate
  total
