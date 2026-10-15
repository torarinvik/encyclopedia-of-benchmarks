## Count ways to climb n stairs using one or two steps per move.
proc climbingStairs*(steps: int64): int64 {.cdecl, exportc: "climbing_stairs".} =
  if steps < 1 or steps > 45: return -1
  var previous = 1'i64
  var current = 1'i64
  var index = 2'i64
  while index <= steps:
    let next = previous + current
    previous = current
    current = next
    inc index
  current
