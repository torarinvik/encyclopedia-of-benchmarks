const MaxVertices = 8
const MaxEdges = 20
const MaxInput = 59
type Rank = array[3, int64]

proc compare(left: Rank, leftTop: bool, right: Rank, rightTop: bool): int =
  if leftTop != rightTop: return (if leftTop: 1 else: -1)
  if leftTop: return 0
  for i in 0..<3:
    if left[i] < right[i]: return -1
    if left[i] > right[i]: return 1
  return 0

proc progress(target: Rank, targetTop: bool, priority: int64,
               bounds: Rank): tuple[digits: Rank, top: bool] =
  result.digits = target
  result.top = targetTop
  if targetTop: return
  let included = if priority < 1: 0 elif priority < 3: 1 elif priority < 5: 2 else: 3
  for i in included..<3: result.digits[i] = 0
  if priority mod 2 == 0: return
  for i in countdown(included - 1, 0):
    if result.digits[i] < bounds[i]:
      result.digits[i] += 1
      for suffix in i + 1..<included: result.digits[suffix] = 0
      return
    result.digits[i] = 0
  result.digits = [0'i64, 0'i64, 0'i64]
  result.top = true

proc small_progress_measure_parity_game_solver*(input: ptr UncheckedArray[int64],
                                                 length: csize_t): int64
    {.cdecl, exportc: "small_progress_measure_parity_game_solver".} =
  if input == nil or length < 6 or length > MaxInput: return -1
  let nRaw = input[0]
  let mRaw = input[1]
  if nRaw < 1 or nRaw > MaxVertices or mRaw < nRaw or mRaw > MaxEdges: return -1
  let n = int(nRaw)
  let m = int(mRaw)
  if length != csize_t(2 + 2 * n + 2 * m): return -1

  var owners: array[MaxVertices, int64]
  var priorities: array[MaxVertices, int64]
  var adjacency: array[MaxVertices, uint16]
  var outdegree: array[MaxVertices, int]
  var bounds: Rank
  var measures: array[MaxVertices, Rank]
  var top: array[MaxVertices, bool]
  var cursor = 2
  for v in 0..<n:
    let owner = input[cursor]
    let priority = input[cursor + 1]
    cursor += 2
    if owner < 0 or owner > 1 or priority < 0 or priority > 5: return -1
    owners[v] = owner
    priorities[v] = priority
    if priority == 1: bounds[0] += 1
    if priority == 3: bounds[1] += 1
    if priority == 5: bounds[2] += 1
  for _ in 0..<m:
    let sourceRaw = input[cursor]
    let destinationRaw = input[cursor + 1]
    cursor += 2
    if sourceRaw < 0 or sourceRaw >= nRaw or destinationRaw < 0 or destinationRaw >= nRaw:
      return -1
    let source = int(sourceRaw)
    let destination = int(destinationRaw)
    let bit = 1'u16 shl destination
    if (adjacency[source] and bit) != 0: return -1
    adjacency[source] = adjacency[source] or bit
    outdegree[source] += 1
  for v in 0..<n:
    if outdegree[v] == 0: return -1

  while true:
    var changed = false
    for v in 0..<n:
      var best: Rank
      var bestTop = owners[v] == 1
      var hasBest = false
      for w in 0..<n:
        if (adjacency[v] and (1'u16 shl w)) == 0: continue
        let candidate = progress(measures[w], top[w], priorities[v], bounds)
        let order = compare(candidate.digits, candidate.top, best, bestTop)
        if not hasBest or (if owners[v] == 0: order < 0 else: order > 0):
          best = candidate.digits
          bestTop = candidate.top
          hasBest = true
      if compare(measures[v], top[v], best, bestTop) < 0:
        measures[v] = best
        top[v] = bestTop
        changed = true
    if not changed: break
  var winners = 0'i64
  for v in 0..<n:
    if not top[v]: winners = winners or (1'i64 shl v)
  return winners
