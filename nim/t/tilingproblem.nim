proc tilingproblem*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tilingproblem".} =
  if length != 1 or input[0] < 0 or input[0] > 91: return -1
  var previous = 1'i64
  var current = 1'i64
  for width in 2 .. input[0]:
    let next = previous + current
    previous = current
    current = next
  current
