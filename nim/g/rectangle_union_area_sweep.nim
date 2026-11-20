const MaxRectangles = 64
const MaxEvents = 128
const TreeSize = 512
const MinCoordinate = -1_000_000_000'i64
const MaxCoordinate = 1_000_000_000'i64

type Event = object
  x, y1, y2, delta: int64

proc siftValues(values: var array[MaxEvents, int64], rootStart, endValue: int) =
  var root = rootStart
  while root * 2 + 1 < endValue:
    var child = root * 2 + 1
    if child + 1 < endValue and values[child] < values[child + 1]: inc child
    if values[root] >= values[child]: return
    swap(values[root], values[child])
    root = child

proc sortValues(values: var array[MaxEvents, int64], count: int) =
  for start in countdown(count div 2 - 1, 0): siftValues(values, start, count)
  for finish in countdown(count - 1, 1):
    swap(values[0], values[finish])
    siftValues(values, 0, finish)

proc siftEvents(events: var array[MaxEvents, Event], rootStart, endValue: int) =
  var root = rootStart
  while root * 2 + 1 < endValue:
    var child = root * 2 + 1
    if child + 1 < endValue and events[child].x < events[child + 1].x: inc child
    if events[root].x >= events[child].x: return
    swap(events[root], events[child])
    root = child

proc sortEvents(events: var array[MaxEvents, Event], count: int) =
  for start in countdown(count div 2 - 1, 0): siftEvents(events, start, count)
  for finish in countdown(count - 1, 1):
    swap(events[0], events[finish])
    siftEvents(events, 0, finish)

proc lowerBound(values: openArray[int64], count: int, target: int64): int =
  var low = 0
  var high = count
  while low < high:
    let middle = low + (high - low) div 2
    if values[middle] < target: low = middle + 1
    else: high = middle
  low

proc update(node, left, right, ql, qr: int, delta: int64,
            ys: openArray[int64], cover, covered: var array[TreeSize, int64]) =
  if ql <= left and right <= qr:
    cover[node] += delta
  else:
    let middle = left + (right - left) div 2
    if ql < middle: update(node * 2, left, middle, ql, qr, delta, ys, cover, covered)
    if qr > middle: update(node * 2 + 1, middle, right, ql, qr, delta, ys, cover, covered)
  if cover[node] > 0: covered[node] = ys[right] - ys[left]
  elif right - left == 1: covered[node] = 0
  else: covered[node] = covered[node * 2] + covered[node * 2 + 1]

proc rectangle_union_area_sweep*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "rectangle_union_area_sweep".} =
  if input.isNil or length < csize_t(1) or length > csize_t(258): return -1
  if input[0] < 0 or input[0] > MaxRectangles: return -1
  let count = int(input[0])
  if int64(length) != int64(1 + 4 * count): return -1
  var ys: array[MaxEvents, int64]
  var events: array[MaxEvents, Event]
  var yCount = 0
  var eventCount = 0
  for i in 0 ..< count:
    let x1 = input[1 + 4*i]
    let y1 = input[2 + 4*i]
    let x2 = input[3 + 4*i]
    let y2 = input[4 + 4*i]
    if x1 < MinCoordinate or x1 > MaxCoordinate or x2 < MinCoordinate or x2 > MaxCoordinate
        or y1 < MinCoordinate or y1 > MaxCoordinate or y2 < MinCoordinate or y2 > MaxCoordinate
        or x1 >= x2 or y1 >= y2: return -1
    ys[yCount] = y1
    ys[yCount + 1] = y2
    yCount += 2
    events[eventCount] = Event(x: x1, y1: y1, y2: y2, delta: 1)
    events[eventCount + 1] = Event(x: x2, y1: y1, y2: y2, delta: -1)
    eventCount += 2
  if count == 0: return 0
  sortValues(ys, yCount)
  var uniqueCount = 1
  for i in 1 ..< yCount:
    if ys[i] != ys[uniqueCount - 1]:
      ys[uniqueCount] = ys[i]
      inc uniqueCount
  sortEvents(events, eventCount)
  var cover: array[TreeSize, int64]
  var covered: array[TreeSize, int64]
  let intervals = uniqueCount - 1
  var area = 0'i64
  var previousX = events[0].x
  var event = 0
  while event < eventCount:
    let x = events[event].x
    area += covered[1] * (x - previousX)
    var finish = event
    while finish < eventCount and events[finish].x == x: inc finish
    for delta in [1'i64, -1'i64]:
      for i in event ..< finish:
        if events[i].delta == delta:
          let low = lowerBound(ys, uniqueCount, events[i].y1)
          let high = lowerBound(ys, uniqueCount, events[i].y2)
          update(1, 0, intervals, low, high, delta, ys, cover, covered)
    previousX = x
    event = finish
  area
