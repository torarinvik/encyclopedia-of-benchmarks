proc problem121*(numTurns: int64): int64 {.cdecl, exportc: "problem121".} =
  if numTurns < 1 or numTurns > 15: return -1
  var denominator = 1'i64
  for turn in 2'i64 .. numTurns + 1: denominator *= turn
  var sequenceCount = 1'i64
  for _ in 0 ..< int(numTurns): sequenceCount *= 2
  var winningWeight = 0'i64
  for mask in 0'i64 ..< sequenceCount:
    var remaining = mask
    var blue = 0'i64
    var weight = 1'i64
    for turn in 0'i64 ..< numTurns:
      if remaining mod 2 == 0: weight *= turn + 1
      else: inc blue
      remaining = remaining div 2
    if 2 * blue > numTurns: winningWeight += weight
  denominator div winningWeight
