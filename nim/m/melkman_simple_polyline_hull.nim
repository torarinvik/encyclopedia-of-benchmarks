type Point = tuple[x, y: int64]

proc turn(points: array[32, Point], a, b, c: int): int64 =
  (points[b].x-points[a].x)*(points[c].y-points[a].y) -
    (points[b].y-points[a].y)*(points[c].x-points[a].x)

proc melkman_simple_polyline_hull*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "melkman_simple_polyline_hull".} =
  if input.isNil or length < 7 or length > 66: return -1
  let raw = input[0]
  if raw < 3 or raw > 32: return -1
  let n = int(raw)
  if length != csize_t(1+2*n): return -1
  var points: array[32, Point]
  for i in 0 ..< n:
    let x = input[1+2*i]
    let y = input[2+2*i]
    if x < -1000 or x > 1000 or y < -1000 or y > 1000: return -1
    points[i] = (x,y)
  let initial = turn(points,0,1,2)
  if initial == 0: return -1
  var deque: array[68,int]
  var first = 32
  var last = 35
  deque[32] = 2
  deque[35] = 2
  if initial > 0:
    deque[33] = 0
    deque[34] = 1
  else:
    deque[33] = 1
    deque[34] = 0
  for i in 3 ..< n:
    if turn(points,deque[first],deque[first+1],i) > 0 and turn(points,deque[last-1],deque[last],i) > 0: continue
    while last > first and turn(points,deque[first],deque[first+1],i) <= 0: inc first
    if last <= first or first == 0: return -1
    dec first
    deque[first] = i
    while last > first and turn(points,deque[last-1],deque[last],i) <= 0: dec last
    if last <= first or last+1 >= 68: return -1
    inc last
    deque[last] = i
  let count = last-first
  var start = 0
  for i in 1 ..< count:
    let a = points[deque[first+i]]
    let b = points[deque[first+start]]
    if a.x < b.x or (a.x == b.x and a.y < b.y): start = i
  let bytes = 8*count
  if output.isNil or capacity < csize_t(bytes): return -2
  var staged: array[256,uint8]
  for i in 0 ..< count:
    let index = uint64(deque[first+(start+i) mod count])
    for b in 0 ..< 8: staged[8*i+b] = uint8((index shr (8*b)) and 255)
  for i in 0 ..< bytes: output[i] = staged[i]
  int64(bytes)
