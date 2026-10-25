type Fraction = tuple[numerator, denominator: int64]
type Group = tuple[lo, hi, stage: int]

proc sameDivision(v: ptr UncheckedArray[int64], order: array[8, int], lo, hi: int): bool =
  let first = 1 + 12 * order[lo]
  for p in lo + 1 ..< hi:
    let current = 1 + 12 * order[p]
    if v[first + 1] != v[current + 1] or v[first + 2] != v[current + 2]: return false
  true

proc scoreFor(v: ptr UncheckedArray[int64], n: int, order: array[8, int], lo, hi,
              team, stage: int, sameDiv: bool): Fraction =
  if stage == 0:
    let cells = n * n
    let winsStart = 1 + 12 * n
    let tiesStart = winsStart + cells
    var won = 0'i64
    var lost = 0'i64
    var tied = 0'i64
    for p in lo ..< hi:
      let other = order[p]
      if other == team: continue
      won += v[winsStart + team * n + other]
      lost += v[winsStart + other * n + team]
      tied += v[tiesStart + team * n + other]
    let games = won + lost + tied
    return (2 * won + tied, (if games == 0: 1'i64 else: 2 * games))
  let base = 1 + 12 * team
  if stage >= 1 and stage <= 3:
    let field = (if stage == 1: 3 else: (if stage == 2: 5 else: 7))
    let games = v[base + field + 1]
    return (v[base + field], (if games == 0: 1'i64 else: 2 * games))
  if stage == 4: return (v[base + (if sameDiv: 9 else: 10)], 1'i64)
  (v[base + 11], 1'i64)

proc compare(a, b: Fraction): int =
  let left = a.numerator * b.denominator
  let right = b.numerator * a.denominator
  (if left > right: 1 else: (if left < right: -1 else: 0))

proc refine(v: ptr UncheckedArray[int64], n: int, order: var array[8, int],
            lo, hi, stage: int, sameDiv: bool, output: var seq[Group]) =
  for i in lo + 1 ..< hi:
    let item = order[i]
    let itemScore = scoreFor(v, n, order, lo, hi, item, stage, sameDiv)
    var j = i
    while j > lo and compare(itemScore, scoreFor(v, n, order, lo, hi, order[j - 1], stage, sameDiv)) > 0:
      order[j] = order[j - 1]
      dec j
    order[j] = item
  let best = scoreFor(v, n, order, lo, hi, order[lo], stage, sameDiv)
  var split = false
  for i in lo + 1 ..< hi:
    if compare(best, scoreFor(v, n, order, lo, hi, order[i], stage, sameDiv)) != 0: split = true
  if not split:
    output.add((lo, hi, stage + 1))
    return
  var start = lo
  while start < hi:
    let value = scoreFor(v, n, order, lo, hi, order[start], stage, sameDiv)
    var finish = start + 1
    while finish < hi and compare(value, scoreFor(v, n, order, lo, hi, order[finish], stage, sameDiv)) == 0:
      inc finish
    output.add((start, finish, 0))
    start = finish

proc sweepResult(v: ptr UncheckedArray[int64], n: int, order: array[8, int], lo, hi: int): tuple[kind, position: int] =
  let cells = n * n
  let winsStart = 1 + 12 * n
  let tiesStart = winsStart + cells
  for position in 0 ..< hi - lo:
    let team = order[lo + position]
    var win = true
    var lose = true
    for p in lo ..< hi:
      let other = order[p]
      if other == team: continue
      let won = v[winsStart + team * n + other]
      let lost = v[winsStart + other * n + team]
      let tied = v[tiesStart + team * n + other]
      if won + lost + tied == 0 or tied != 0: win = false; lose = false
      if lost != 0: win = false
      if won != 0: lose = false
    if win: return (1, position)
    if lose: return (-1, position)
  (0, 0)

proc prolangs_football_tiebreaks*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "prolangs_football_tiebreaks".} =
  if input == nil or length < 1 or input[0] < 2 or input[0] > 8: return -2
  let n = int(input[0])
  let cells = n * n
  if length != csize_t(1 + 12 * n + 2 * cells): return -2
  var ids: array[8, int]
  for i in 0 ..< n:
    let base = 1 + 12 * i
    let id = input[base]
    if id < 0 or id > 31 or input[base + 1] < 0 or input[base + 1] > 1 or input[base + 2] < 0 or input[base + 2] > 2: return -2
    for field in [3, 5, 7]:
      let points = input[base + field]
      let games = input[base + field + 1]
      if games < 0 or games > 64 or points < 0 or points > 2 * games: return -2
    for field in 9 .. 11:
      if input[base + field] < -4096 or input[base + field] > 4096: return -2
    for prior in 0 ..< i:
      if input[1 + 12 * prior] == id: return -2
    ids[i] = i

  let winsStart = 1 + 12 * n
  let tiesStart = winsStart + cells
  for i in 0 ..< n:
    for j in 0 ..< n:
      let wins = input[winsStart + i * n + j]
      let ties = input[tiesStart + i * n + j]
      if wins < 0 or wins > 64 or ties < 0 or ties > 64 or
          (i == j and (wins != 0 or ties != 0)) or ties != input[tiesStart + j * n + i]: return -2

  for i in 1 ..< n:
    let item = ids[i]
    var j = i
    while j > 0 and (input[1 + 12 * ids[j - 1] + 1] > input[1 + 12 * item + 1] or
        (input[1 + 12 * ids[j - 1] + 1] == input[1 + 12 * item + 1] and input[1 + 12 * ids[j - 1]] > input[1 + 12 * item])):
      ids[j] = ids[j - 1]
      dec j
    ids[j] = item

  var groups: seq[Group] = @[(0, n, 0)]
  while true:
    var next: seq[Group] = @[]
    var active = false
    for group in groups:
      let lo = group.lo
      let hi = group.hi
      let stage = group.stage
      if hi - lo <= 1 or stage >= 6:
        next.add((lo, hi, 6))
        continue
      active = true
      let sameDiv = sameDivision(input, ids, lo, hi)
      if stage == 0:
        if sameDiv or hi - lo == 2:
          refine(input, n, ids, lo, hi, 0, sameDiv, next)
        else:
          let sweep = sweepResult(input, n, ids, lo, hi)
          if sweep.kind > 0:
            swap(ids[lo], ids[lo + sweep.position])
            next.add((lo, lo + 1, 0))
            next.add((lo + 1, hi, 0))
          elif sweep.kind < 0:
            swap(ids[hi - 1], ids[lo + sweep.position])
            next.add((lo, hi - 1, 0))
            next.add((hi - 1, hi, 0))
          else:
            next.add((lo, hi, 1))
      elif stage == 1 and not sameDiv:
        next.add((lo, hi, 2))
      elif stage == 3:
        var skipCommon = false
        for p in lo ..< hi:
          if input[1 + 12 * ids[p] + 8] < 4: skipCommon = true
        if skipCommon: next.add((lo, hi, 4))
        else: refine(input, n, ids, lo, hi, stage, sameDiv, next)
      else:
        refine(input, n, ids, lo, hi, stage, sameDiv, next)
    groups = next
    if not active: break

  var result = 0'i64
  for i in 0 ..< n: result = result * 32 + input[1 + 12 * ids[i]]
  result
