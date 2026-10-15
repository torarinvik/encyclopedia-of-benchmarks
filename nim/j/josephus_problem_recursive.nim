proc josephus_solve(n, step: int64): int64 =
  if n == 1: return 0
  (josephus_solve(n - 1, step) + step mod n) mod n
proc josephus_problem_recursive*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "josephus_problem_recursive".} =
  if length != 2: return -1
  let n = values[0]
  let step = values[1]
  if n < 1 or n > 256 or step < 1: return -1
  josephus_solve(n, step) + 1
