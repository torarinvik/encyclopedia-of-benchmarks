const MaxN = 16
const MaxInput = 34
const TableSize = 32

proc gcdPositive(aValue, bValue: int): int =
  var a = aValue
  var b = bValue
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc max_points_on_a_line*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "max_points_on_a_line".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN or int(length) != 1 + 2 * int(nValue): return -1
  let n = int(nValue)
  var xs: array[MaxN, int]
  var ys: array[MaxN, int]
  for i in 0 ..< n:
    let xv = input[1 + 2 * i]
    let yv = input[2 + 2 * i]
    if xv < -100 or xv > 100 or yv < -100 or yv > 100: return -1
    xs[i] = int(xv)
    ys[i] = int(yv)
    for j in 0 ..< i:
      if xs[i] == xs[j] and ys[i] == ys[j]: return -1
  if n == 1: return 1
  var answer = 2
  for anchor in 0 ..< n:
    var keys: array[TableSize, int]
    var counts: array[TableSize, int]
    for slot in 0 ..< TableSize: keys[slot] = -1
    var best = 0
    for other in 0 ..< n:
      if other == anchor: continue
      var dx = xs[other] - xs[anchor]
      var dy = ys[other] - ys[anchor]
      let divisor = gcdPositive(abs(dx), abs(dy))
      dx = dx div divisor
      dy = dy div divisor
      if dx < 0 or (dx == 0 and dy < 0):
        dx = -dx
        dy = -dy
      let directionKey = dx * 401 + dy + 200
      var slot = directionKey mod TableSize
      while keys[slot] != -1 and keys[slot] != directionKey:
        slot = (slot + 1) mod TableSize
      if keys[slot] == -1: keys[slot] = directionKey
      inc counts[slot]
      best = max(best, counts[slot])
    answer = max(answer, best + 1)
  int64(answer)
