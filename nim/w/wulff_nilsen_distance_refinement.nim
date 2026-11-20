const
  MaxN = 8
  MaxM = 28
  MaxInput = 93
  Scale = 86_093_442'i64
  Inf = high(int64) div 4

proc evenIndex(x: int, threshold: int64, sample: array[4, array[8, int]],
               distance: array[8, array[8, int64]]): int =
  if distance[x][sample[2][x]] <= threshold: 2 else: 0

proc refineFurther(u, v, iu: int, sample: array[4, array[8, int]],
                   bunch: array[8, array[8, bool]], distance: array[8, array[8, int64]]): bool =
  if iu < 2: return false
  bunch[v][sample[0][u]] or bunch[u][sample[1][v]] or
    bunch[v][sample[iu][u]] or bunch[u][sample[iu + 1][v]]

proc wulff_nilsen_distance_refinement*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "wulff_nilsen_distance_refinement".} =
  if input.isNil or length < 8 or length > MaxInput: return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 2 or n64 > MaxN or m64 < 0 or m64 > MaxM: return -1
  let n = int(n64); let m = int(m64)
  if length != csize_t(8 + 3 * m): return -1
  let full = (1'i64 shl n) - 1
  var masks: array[3, int64]
  for i in 0 .. 2:
    masks[i] = input[2 + i]
    if masks[i] <= 0 or (masks[i] and not full) != 0: return -1
  if (masks[1] and not masks[0]) != 0 or (masks[2] and not masks[1]) != 0: return -1

  var distance: array[8, array[8, int64]]
  for u in 0 ..< n:
    for v in 0 ..< n: distance[u][v] = if u == v: 0 else: Inf
  var prevU = -1
  var prevV = -1
  for e in 0 ..< m:
    let at = 5 + 3 * e
    let u64 = input[at]; let v64 = input[at + 1]; let weight = input[at + 2]
    if u64 < 0 or u64 >= n64 or v64 <= u64 or v64 >= n64 or
       weight < Scale or weight > 100 * Scale or weight mod Scale != 0: return -1
    let u = int(u64); let v = int(v64)
    if u < prevU or (u == prevU and v <= prevV): return -1
    prevU = u; prevV = v
    distance[u][v] = weight; distance[v][u] = weight
  let query = 5 + 3 * m
  let source64 = input[query]; let target64 = input[query + 1]; let estimate = input[query + 2]
  if source64 < 0 or source64 >= n64 or target64 < 0 or target64 >= n64 or source64 == target64 or estimate <= 0 or estimate mod Scale != 0: return -1
  let source = int(source64); let target = int(target64)
  for mid in 0 ..< n:
    for u in 0 ..< n:
      if distance[u][mid] == Inf: continue
      for v in 0 ..< n:
        let candidate = distance[u][mid] + distance[mid][v]
        if candidate < distance[u][v]: distance[u][v] = candidate
  for u in 0 ..< n:
    for v in 0 ..< n:
      if distance[u][v] == Inf: return -1
  if estimate < distance[source][target] or estimate > 768 * distance[source][target]: return -1

  var sample: array[4, array[8, int]]
  for x in 0 ..< n:
    sample[0][x] = x
    for level in 1 ..< 4:
      var chosen = -1
      for y in 0 ..< n:
        if ((masks[level - 1] shr y) and 1) != 0 and
            (chosen < 0 or distance[x][y] < distance[x][chosen] or
             (distance[x][y] == distance[x][chosen] and y < chosen)):
          chosen = y
      sample[level][x] = chosen
  let layers = [full, masks[0], masks[1], masks[2], 0'i64]
  var bunch: array[8, array[8, bool]]
  for center in 0 ..< n:
    for level in 0 ..< 4:
      var boundary = Inf
      for y in 0 ..< n:
        if ((layers[level + 1] shr y) and 1) != 0: boundary = min(boundary, distance[center][y])
      for y in 0 ..< n:
        if ((layers[level] shr y) and 1) != 0 and ((layers[level + 1] shr y) and 1) == 0 and distance[center][y] < boundary:
          bunch[center][y] = true
  var value = estimate
  var iu = evenIndex(source, value, sample, distance)
  if not refineFurther(source, target, iu, sample, bunch, distance): return value
  var iteration = 0
  while refineFurther(source, target, iu, sample, bunch, distance) and iteration <= 15:
    value = (2 * value) div 3
    iu = evenIndex(source, value, sample, distance)
    inc iteration
  let upper = evenIndex(source, (3 * value) div 2, sample, distance)
  if upper < 2: return -1
  var pivot = sample[0][source]
  if bunch[target][pivot]: return distance[source][pivot] + distance[target][pivot]
  pivot = sample[1][target]
  if bunch[source][pivot]: return distance[source][pivot] + distance[target][pivot]
  pivot = sample[upper][source]
  if bunch[target][pivot]: return distance[source][pivot] + distance[target][pivot]
  pivot = sample[upper + 1][target]
  distance[source][pivot] + distance[target][pivot]
