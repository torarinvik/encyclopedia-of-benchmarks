## Shootout fib2: uncached recursion with fib(0) = fib(1) = 1.
proc fib2Value(n: int64): int64 =
  if n < 2: return 1
  fib2Value(n - 2) + fib2Value(n - 1)

proc fib2*(n: int64): int64 {.cdecl, exportc: "fib2".} =
  if n < 0 or n > 30: return -1
  fib2Value(n)
