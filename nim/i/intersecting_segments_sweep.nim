const
  MaxSegments = 24
  MaxInput = 98
  CoordMin = -100'i64
  CoordMax = 100'i64

type
  Segment = object
    x1, y1, x2, y2: int64
  Event = object
    x: int64
    id: int
    starts: bool

proc orientation(ax, ay, bx, by, cx, cy: int64): int64 =
  (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)

proc between(a, b, point: int64): bool =
  if a <= b: return a <= point and point <= b
  b <= point and point <= a

proc onSegment(ax, ay, bx, by, px, py: int64): bool =
  orientation(ax, ay, bx, by, px, py) == 0 and
    between(ax, bx, px) and between(ay, by, py)

proc intersects(a, b: Segment): bool =
  let abC = orientation(a.x1, a.y1, a.x2, a.y2, b.x1, b.y1)
  let abD = orientation(a.x1, a.y1, a.x2, a.y2, b.x2, b.y2)
  let cdA = orientation(b.x1, b.y1, b.x2, b.y2, a.x1, a.y1)
  let cdB = orientation(b.x1, b.y1, b.x2, b.y2, a.x2, a.y2)
  if abC == 0 and onSegment(a.x1, a.y1, a.x2, a.y2, b.x1, b.y1): return true
  if abD == 0 and onSegment(a.x1, a.y1, a.x2, a.y2, b.x2, b.y2): return true
  if cdA == 0 and onSegment(b.x1, b.y1, b.x2, b.y2, a.x1, a.y1): return true
  if cdB == 0 and onSegment(b.x1, b.y1, b.x2, b.y2, a.x2, a.y2): return true
  ((abC < 0 and abD > 0) or (abC > 0 and abD < 0)) and
    ((cdA < 0 and cdB > 0) or (cdA > 0 and cdB < 0))

proc compareAtX(a: Segment, idA: int, b: Segment, idB: int, x: int64): int =
  let adx = a.x2 - a.x1
  let bdx = b.x2 - b.x1
  let aNum = a.y1 * adx + (a.y2 - a.y1) * (x - a.x1)
  let bNum = b.y1 * bdx + (b.y2 - b.y1) * (x - b.x1)
  let left = aNum * bdx
  let right = bNum * adx
  if left < right: return -1
  if left > right: return 1
  let aSlope = (a.y2 - a.y1) * bdx
  let bSlope = (b.y2 - b.y1) * adx
  if aSlope < bSlope: return -1
  if aSlope > bSlope: return 1
  if idA < idB: return -1
  if idA > idB: return 1
  0

proc intersecting_segments_sweep*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "intersecting_segments_sweep".} =
  if input == nil or length < 1 or length > MaxInput: return -1
  let countRaw = input[0]
  if countRaw < 0 or countRaw > MaxSegments or length != csize_t(1 + 4 * countRaw): return -1
  let count = int(countRaw)
  var usedX: array[201, bool]
  var segments: array[MaxSegments, Segment]
  var events: array[2 * MaxSegments, Event]
  var eventCount = 0
  for id in 0..<count:
    let offset = 1 + 4 * id
    let segment = Segment(x1: input[offset], y1: input[offset + 1],
                          x2: input[offset + 2], y2: input[offset + 3])
    if segment.x1 < CoordMin or segment.x1 > CoordMax or segment.x2 < CoordMin or segment.x2 > CoordMax or
        segment.y1 < CoordMin or segment.y1 > CoordMax or segment.y2 < CoordMin or segment.y2 > CoordMax or
        segment.x1 >= segment.x2: return -1
    let firstX = int(segment.x1 - CoordMin)
    let secondX = int(segment.x2 - CoordMin)
    if usedX[firstX] or usedX[secondX]: return -1
    usedX[firstX] = true
    usedX[secondX] = true
    segments[id] = segment
    events[eventCount] = Event(x: segment.x1, id: id, starts: true)
    inc eventCount
    events[eventCount] = Event(x: segment.x2, id: id, starts: false)
    inc eventCount
  var sortIndex = 1
  while sortIndex < eventCount:
    let item = events[sortIndex]
    var position = sortIndex
    while position > 0 and events[position - 1].x > item.x:
      events[position] = events[position - 1]
      dec position
    events[position] = item
    inc sortIndex

  var active: array[MaxSegments, int]
  var activeCount = 0
  for eventIndex in 0..<eventCount:
    let event = events[eventIndex]
    if event.starts:
      var position = 0
      while position < activeCount and compareAtX(segments[active[position]], active[position],
          segments[event.id], event.id, event.x) < 0:
        inc position
      if position > 0 and intersects(segments[active[position - 1]], segments[event.id]): return 1
      if position < activeCount and intersects(segments[active[position]], segments[event.id]): return 1
      var move = activeCount
      while move > position:
        active[move] = active[move - 1]
        dec move
      active[position] = event.id
      inc activeCount
    else:
      var position = 0
      while position < activeCount and active[position] != event.id: inc position
      if position == activeCount: return -1
      if position > 0 and position + 1 < activeCount and
          intersects(segments[active[position - 1]], segments[active[position + 1]]): return 1
      var move = position
      while move + 1 < activeCount:
        active[move] = active[move + 1]
        inc move
      dec activeCount
  0
