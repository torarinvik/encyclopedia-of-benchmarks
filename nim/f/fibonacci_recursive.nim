## Naive recursive Fibonacci on a deliberately small domain.
proc fibonacciValue(n: int64): int64 =
  if n < 2: return n
  fibonacciValue(n - 1) + fibonacciValue(n - 2)

proc fibonacci_recursive*(n: int64): int64 {.cdecl, exportc: "fibonacci_recursive".} =
  if n < 0 or n > 30: return -1
  fibonacciValue(n)
