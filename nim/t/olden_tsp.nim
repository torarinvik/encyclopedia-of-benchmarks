import std/math

const MaxCities = 7
const ConquerThreshold = 3
const Scale = 1000.0

proc cityDistance(x, y: array[MaxCities, int64], a, b: int): float64 =
  let dx = float64(x[a] - x[b])
  let dy = float64(y[a] - y[b])
  sqrt(dx * dx + dy * dy)

proc subtreeSize(node, count: int): int =
  if node >= count: return 0
  1 + subtreeSize(2 * node + 1, count) + subtreeSize(2 * node + 2, count)

proc collectPostorder(node, count: int, order: var array[MaxCities, int], length: var int) =
  if node >= count: return
  collectPostorder(2 * node + 1, count, order, length)
  collectPostorder(2 * node + 2, count, order, length)
  order[length] = node
  inc length

proc reverseCycle(start, size: int, nextNode, prevNode: var array[MaxCities, int]) =
  var current = start
  for _ in 0 ..< size:
    let oldNext = nextNode[current]
    let oldPrev = prevNode[current]
    nextNode[current] = oldPrev
    prevNode[current] = oldNext
    current = oldNext

proc conquer(order: array[MaxCities, int], count: int, x, y: array[MaxCities, int64],
             nextNode, prevNode: var array[MaxCities, int]): int =
  let cycle = order[0]
  nextNode[cycle] = cycle
  prevNode[cycle] = cycle
  for pointIndex in 1 ..< count:
    let point = order[pointIndex]
    var min = cycle
    var mindist = cityDistance(x, y, point, cycle)
    var tmp = nextNode[cycle]
    while tmp != cycle:
      let test = cityDistance(x, y, tmp, point)
      if test < mindist: mindist = test; min = tmp
      tmp = nextNode[tmp]
    let nextCity = nextNode[min]
    let prevCity = prevNode[min]
    let minToNext = cityDistance(x, y, min, nextCity)
    let minToPrev = cityDistance(x, y, min, prevCity)
    let pointToNext = cityDistance(x, y, point, nextCity)
    let pointToPrev = cityDistance(x, y, point, prevCity)
    if pointToPrev - minToPrev < pointToNext - minToNext:
      nextNode[prevCity] = point; prevNode[point] = prevCity
      nextNode[point] = min; prevNode[min] = point
    else:
      prevNode[nextCity] = point; nextNode[point] = nextCity
      nextNode[min] = point; prevNode[point] = min
  cycle

proc mergeCycles(a, b, point, sizeA, sizeB: int, x, y: array[MaxCities, int64],
                 nextNode, prevNode: var array[MaxCities, int]): int =
  var min = a
  var mindist = cityDistance(x, y, point, a)
  var tmp = nextNode[a]
  while tmp != a:
    let test = cityDistance(x, y, point, tmp)
    if test < mindist: mindist = test; min = tmp
    tmp = nextNode[tmp]
  var nextCity = nextNode[min]
  var prevCity = prevNode[min]
  var minToNext = cityDistance(x, y, min, nextCity)
  var minToPrev = cityDistance(x, y, min, prevCity)
  var pointToNext = cityDistance(x, y, point, nextCity)
  var pointToPrev = cityDistance(x, y, point, prevCity)
  var n1, p1: int
  var tton1, ttop1: float64
  if pointToPrev - minToPrev < pointToNext - minToNext:
    p1 = prevCity; n1 = min; tton1 = mindist; ttop1 = pointToPrev
  else:
    p1 = min; n1 = nextCity; ttop1 = mindist; tton1 = pointToNext

  min = b
  mindist = cityDistance(x, y, point, b)
  tmp = nextNode[b]
  while tmp != b:
    let test = cityDistance(x, y, point, tmp)
    if test < mindist: mindist = test; min = tmp
    tmp = nextNode[tmp]
  nextCity = nextNode[min]; prevCity = prevNode[min]
  minToNext = cityDistance(x, y, min, nextCity); minToPrev = cityDistance(x, y, min, prevCity)
  pointToNext = cityDistance(x, y, point, nextCity); pointToPrev = cityDistance(x, y, point, prevCity)
  var n2, p2: int
  var tton2, ttop2: float64
  if pointToPrev - minToPrev < pointToNext - minToNext:
    p2 = prevCity; n2 = min; tton2 = mindist; ttop2 = pointToPrev
  else:
    p2 = min; n2 = nextCity; ttop2 = mindist; tton2 = pointToNext

  let n1ToN2 = cityDistance(x, y, n1, n2)
  let n1ToP2 = cityDistance(x, y, n1, p2)
  let p1ToN2 = cityDistance(x, y, p1, n2)
  let p1ToP2 = cityDistance(x, y, p1, p2)
  var best = ttop1 + ttop2 + n1ToN2
  var choice = 1
  var test = ttop1 + tton2 + n1ToP2
  if test < best: choice = 2; best = test
  test = tton1 + ttop2 + p1ToN2
  if test < best: choice = 3; best = test
  test = tton1 + tton2 + p1ToP2
  if test < best: choice = 4

  if choice == 1:
    reverseCycle(n2, sizeB, nextNode, prevNode)
    nextNode[p1] = point; prevNode[point] = p1
    nextNode[point] = p2; prevNode[p2] = point
    nextNode[n2] = n1; prevNode[n1] = n2
  elif choice == 2:
    nextNode[p1] = point; prevNode[point] = p1
    nextNode[point] = n2; prevNode[n2] = point
    nextNode[p2] = n1; prevNode[n1] = p2
  elif choice == 3:
    nextNode[p2] = point; prevNode[point] = p2
    nextNode[point] = n1; prevNode[n1] = point
    nextNode[p1] = n2; prevNode[n2] = p1
  else:
    reverseCycle(n1, sizeA, nextNode, prevNode)
    nextNode[n1] = point; prevNode[point] = n1
    nextNode[point] = n2; prevNode[n2] = point
    nextNode[p2] = p1; prevNode[p1] = p2
  point

proc solveSubtree(node, count: int, x, y: array[MaxCities, int64],
                  nextNode, prevNode: var array[MaxCities, int]): int =
  let size = subtreeSize(node, count)
  if size <= ConquerThreshold:
    var order: array[MaxCities, int]
    var orderCount = 0
    collectPostorder(node, count, order, orderCount)
    return conquer(order, orderCount, x, y, nextNode, prevNode)
  let left = 2 * node + 1
  let right = 2 * node + 2
  let leftCycle = solveSubtree(left, count, x, y, nextNode, prevNode)
  let rightCycle = solveSubtree(right, count, x, y, nextNode, prevNode)
  mergeCycles(leftCycle, rightCycle, node, subtreeSize(left, count), subtreeSize(right, count), x, y, nextNode, prevNode)

proc olden_tsp*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "olden_tsp".} =
  if input == nil or (length != 7 and length != 15): return -1
  let countValue = input[0]
  if countValue != 3 and countValue != 7: return -1
  let count = int(countValue)
  if length != csize_t(1 + 2 * count): return -1
  var x, y: array[MaxCities, int64]
  var nextNode, prevNode: array[MaxCities, int]
  for city in 0 ..< count:
    x[city] = input[1 + 2 * city]
    y[city] = input[2 + 2 * city]
    if x[city] < -8 or x[city] > 8 or y[city] < -8 or y[city] > 8: return -1
  discard solveSubtree(0, count, x, y, nextNode, prevNode)
  var tourLength = 0.0
  var city = 0
  for _ in 0 ..< count:
    let following = nextNode[city]
    tourLength += cityDistance(x, y, city, following)
    city = following
  int64(floor(tourLength * Scale + 0.5))
