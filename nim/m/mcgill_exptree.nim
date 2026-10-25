const MaxLeaves = 4
type
  Combination = object
    left, right: int64
    operation: int
  SearchState = object
    count, depthLimit: int
    goal, best: int64
    stopped: bool
    work: array[2 * MaxLeaves, int64]
    current, saved: array[MaxLeaves, Combination]

proc distanceFrom(a, b: int64): int64 =
  if a >= b: a - b else: b - a

proc apply(a, b: int64, operation: int): int64 =
  case operation
  of 1: a + b
  of 2: a - b
  of 3: a * b
  else: a div b

proc search(state: var SearchState, depth: int, used: uint32) =
  if state.stopped: return
  if depth == state.depthLimit:
    let candidate = state.work[state.count + depth - 1]
    if distanceFrom(candidate, state.goal) < distanceFrom(state.best, state.goal):
      state.best = candidate
      for i in 0 ..< depth: state.saved[i] = state.current[i]
      if state.best == state.goal: state.stopped = true
    return
  for operation in 1 .. 4:
    if state.stopped: break
    for first in 0 ..< state.count + depth:
      if state.stopped: break
      if (used and (1'u32 shl first)) != 0: continue
      for second in 0 ..< first:
        if state.stopped: break
        if (used and (1'u32 shl second)) != 0: continue
        var left = state.work[first]
        var right = state.work[second]
        if operation in {3, 4} and (left == 1 or right == 1): continue
        if left == 0 or right == 0: continue
        if operation == 4 and left mod right != 0: continue
        if operation in {2, 4} and left < right: swap(left, right)
        state.current[depth] = Combination(left: left, right: right, operation: operation)
        state.work[state.count + depth] = apply(left, right, operation)
        search(state, depth + 1, used or (1'u32 shl first) or (1'u32 shl second))

proc mcgill_exptree*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "mcgill_exptree".} =
  if input == nil or length < 3 or length > 6: return -1
  let goal = input[0]
  let rawCount = input[1]
  if goal < 1 or goal > 1_000_000_000 or rawCount < 1 or rawCount > MaxLeaves or
      length != csize_t(rawCount + 2): return -1
  var state = SearchState(count: int(rawCount), goal: goal)
  for i in 0 ..< state.count:
    let value = input[2 + i]
    if value < 1 or value > 100: return -1
    state.work[i] = value
  for i in 0 ..< state.count:
    if distanceFrom(state.work[i], state.goal) < distanceFrom(state.best, state.goal):
      state.best = state.work[i]
  if state.best == state.goal: return state.best
  for depthLimit in 1 ..< state.count:
    state.depthLimit = depthLimit
    search(state, 0, 0)
    if state.stopped: break
  state.best
