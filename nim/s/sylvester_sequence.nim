## Recursive Sylvester recurrence on the signed 64-bit benchmark domain.
proc sylvesterTerm(n: int64): int64 =
  if n == 1:
    return 2
  let previous = sylvesterTerm(n - 1)
  return previous * (previous - 1) + 1

proc sylvester_sequence*(n: int64): int64 {.cdecl, exportc: "sylvester_sequence".} =
  if n < 1 or n > 7:
    return -1
  return sylvesterTerm(n)
