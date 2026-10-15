proc josephus_problem*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "josephus_problem".} =
  if length != 2: return -1
  let n = values[0]
  let step = values[1]
  if n < 1 or n > 100000 or step < 1: return -1
  var winner = 0'i64
  var size = 1'i64
  while size <= n:
    winner = (winner + step mod size) mod size
    inc size
  winner + 1
