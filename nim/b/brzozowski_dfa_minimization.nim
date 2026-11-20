proc brzozowski_dfa_minimization*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "brzozowski_dfa_minimization".} =
  if input.isNil or length < 3 or length > 10:
    return -1
  let n64 = input[0]
  let start64 = input[1]
  let accepting64 = input[2]
  if n64 < 1 or n64 > 3 or start64 < 0 or start64 >= n64:
    return -1
  if accepting64 < 0 or accepting64 >= (1'i64 shl int(n64)):
    return -1
  let n = int(n64)
  if length != csize_t(3 + 2 * n):
    return -1
  let start = int(start64)
  var transitions = newSeq[int](6)
  for state in 0 ..< n:
    for symbol in 0 ..< 2:
      let target = input[3 + 2 * state + symbol]
      if target < 0 or target >= n64:
        return -1
      transitions[state * 2 + symbol] = int(target)

  var firstMasks = newSeq[int](8)
  var firstDelta = newSeq[int](16)
  var firstFinal = newSeq[bool](8)
  var firstId = newSeq[int](8)
  for i in 0 ..< 8:
    firstId[i] = -1
  var firstCount = 1
  firstMasks[0] = int(accepting64)
  firstId[int(accepting64)] = 0
  var cursor = 0
  while cursor < firstCount:
    let subset = firstMasks[cursor]
    firstFinal[cursor] = ((subset shr start) and 1) != 0
    for symbol in 0 ..< 2:
      var predecessor = 0
      for state in 0 ..< n:
        if (subset and (1 shl transitions[state * 2 + symbol])) != 0:
          predecessor = predecessor or (1 shl state)
      if firstId[predecessor] < 0:
        firstId[predecessor] = firstCount
        firstMasks[firstCount] = predecessor
        inc firstCount
      firstDelta[cursor * 2 + symbol] = firstId[predecessor]
    inc cursor

  var firstAccepting = 0
  for state in 0 ..< firstCount:
    if firstFinal[state]:
      firstAccepting = firstAccepting or (1 shl state)

  var secondQueue = newSeq[int](256)
  var secondSeen = newSeq[bool](256)
  var secondCount = 1
  secondQueue[0] = firstAccepting
  secondSeen[firstAccepting] = true
  cursor = 0
  while cursor < secondCount:
    let subset = secondQueue[cursor]
    for symbol in 0 ..< 2:
      var predecessor = 0
      for state in 0 ..< firstCount:
        if (subset and (1 shl firstDelta[state * 2 + symbol])) != 0:
          predecessor = predecessor or (1 shl state)
      if not secondSeen[predecessor]:
        secondSeen[predecessor] = true
        secondQueue[secondCount] = predecessor
        inc secondCount
    inc cursor
  int64(secondCount)
