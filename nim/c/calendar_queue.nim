const
  MaxOps = 128
  MaxLive = 64
  MaxBuckets = 64
  MaxPriority = 1_000_000'i64
  MaxInput = 1 + 2 * MaxOps + 1

type
  Event = object
    priority: int64
    id: int64
    next: int
    active: bool
  Calendar = object
    events: array[MaxLive, Event]
    heads: array[MaxBuckets, int]
    bucketCount: int
    live: int
    nextId: int64
    lastPriority: int64
    lastBucket: int
    widthNum: int64
    widthDen: int64
    topNum: int64
    topDen: int64

proc less(a, b: Event): bool =
  a.priority < b.priority or (a.priority == b.priority and a.id < b.id)

proc gcd(a0, b0: int64): int64 =
  var a = a0
  var b = b0
  while b != 0:
    let r = a mod b
    a = b
    b = r
  a

proc virtualBucket(q: Calendar, priority: int64): int =
  int((priority * q.widthDen) div q.widthNum)

proc resetCursor(q: var Calendar, priority: int64) =
  let virtualIndex = virtualBucket(q, priority)
  q.lastBucket = virtualIndex mod q.bucketCount
  q.topNum = (2 * int64(virtualIndex) + 3) * q.widthNum
  q.topDen = 2 * q.widthDen

proc insert(q: var Calendar, slot: int) =
  let bucket = virtualBucket(q, q.events[slot].priority) mod q.bucketCount
  var previous = MaxLive
  var current = q.heads[bucket]
  while current != MaxLive and less(q.events[current], q.events[slot]):
    previous = current
    current = q.events[current].next
  q.events[slot].next = current
  if previous == MaxLive: q.heads[bucket] = slot
  else: q.events[previous].next = slot

proc newWidth(q: Calendar): tuple[num, den: int64] =
  var ordered: array[MaxLive, Event]
  var count = 0
  for event in q.events:
    if not event.active: continue
    var at = count
    while at > 0 and less(event, ordered[at - 1]):
      ordered[at] = ordered[at - 1]
      dec at
    ordered[at] = event
    inc count
  if count < 2: return (1'i64, 1'i64)
  let samples = if count <= 5: count else: min(25, 5 + count div 10)
  let gapCount = samples - 1
  var sum = 0'i64
  for i in 0 ..< gapCount: sum += ordered[i + 1].priority - ordered[i].priority
  if sum == 0: return (1'i64, 1'i64)
  var keptSum = 0'i64
  var kept = 0'i64
  for i in 0 ..< gapCount:
    let gap = ordered[i + 1].priority - ordered[i].priority
    if gap * int64(gapCount) <= 2 * sum:
      keptSum += gap
      inc kept
  if keptSum == 0 or kept == 0: return (1'i64, 1'i64)
  let numerator = 3 * keptSum
  let divisor = gcd(numerator, kept)
  (numerator div divisor, kept div divisor)

proc resize(q: var Calendar, newCount: int) =
  let width = newWidth(q)
  q.bucketCount = newCount
  q.widthNum = width.num
  q.widthDen = width.den
  for head in q.heads.mitems: head = MaxLive
  resetCursor(q, q.lastPriority)
  for slot in 0 ..< MaxLive:
    if q.events[slot].active: insert(q, slot)

proc enqueue(q: var Calendar, priority: int64): bool =
  if priority < 0 or priority > MaxPriority or priority < q.lastPriority or q.live == MaxLive: return false
  var slot = MaxLive
  for i in 0 ..< MaxLive:
    if not q.events[i].active:
      slot = i
      break
  if slot == MaxLive: return false
  q.events[slot] = Event(priority: priority, id: q.nextId, next: MaxLive, active: true)
  inc q.nextId
  inc q.live
  insert(q, slot)
  if q.live > 2 * q.bucketCount: resize(q, q.bucketCount * 2)
  true

proc dequeue(q: var Calendar, outEvent: var Event): bool =
  if q.live == 0: return false
  var bucket = q.lastBucket
  while true:
    let slot = q.heads[bucket]
    if slot != MaxLive and q.events[slot].priority * q.topDen < q.topNum:
      outEvent = q.events[slot]
      q.heads[bucket] = outEvent.next
      q.events[slot].active = false
      dec q.live
      q.lastBucket = bucket
      q.lastPriority = outEvent.priority
      if q.bucketCount > 2 and int64(q.live) < int64(q.bucketCount div 2 - 2): resize(q, q.bucketCount div 2)
      return true
    bucket = (bucket + 1) mod q.bucketCount
    q.topNum += 2 * q.widthNum
    if bucket == q.lastBucket:
      var minimum = MaxLive
      for i in 0 ..< q.bucketCount:
        let head = q.heads[i]
        if head != MaxLive and (minimum == MaxLive or less(q.events[head], q.events[minimum])): minimum = head
      if minimum == MaxLive: return false
      q.lastPriority = q.events[minimum].priority
      resetCursor(q, q.lastPriority)
      bucket = q.lastBucket

proc putI64(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[word * 8 + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc calendar_queue*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "calendar_queue".} =
  if input == nil or length < 1 or length > csize_t(MaxInput): return -1
  let count0 = input[0]
  if count0 < 0 or count0 > MaxOps or int(length) != 1 + 2 * int(count0): return -1
  var q = Calendar(bucketCount: 2, lastPriority: 0, widthNum: 1, widthDen: 1, topNum: 3, topDen: 2)
  for head in q.heads.mitems: head = MaxLive
  var trace: array[2 * MaxOps, int64]
  var dequeued = 0
  for step in 0 ..< int(count0):
    let opcode = input[1 + 2 * step]
    let argument = input[2 + 2 * step]
    if opcode == 1:
      if not enqueue(q, argument): return -1
    elif opcode == 2:
      if argument != 0: return -1
      var event: Event
      if not dequeue(q, event): return -1
      trace[2 * dequeued] = event.id
      trace[2 * dequeued + 1] = event.priority
      inc dequeued
    else: return -1
  let bytes = (1 + 2 * dequeued) * 8
  if output == nil or capacity < csize_t(bytes): return -2
  putI64(output, 0, int64(dequeued))
  for word in 0 ..< 2 * dequeued: putI64(output, word + 1, trace[word])
  int64(bytes)
