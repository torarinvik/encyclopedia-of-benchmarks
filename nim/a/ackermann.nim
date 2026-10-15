## Bounded recursive Ackermann function A(m, n).
proc ackermannValue(m, n: int64): int64 =
  if m == 0: return n + 1
  if n == 0: return ackermannValue(m - 1, 1)
  ackermannValue(m - 1, ackermannValue(m, n - 1))

proc ackermann*(m, n: int64): int64 {.cdecl, exportc: "ackermann".} =
  if m < 0 or m > 3 or n < 0 or n > 5: return -1
  ackermannValue(m, n)
