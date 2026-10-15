## Count transitions in the classic Collatz sequence for a bounded input.
proc collatz*(n: int64): int64 {.cdecl, exportc: "collatz".} =
  if n < 1 or n > 1_000_000: return -1
  var current = n
  var steps: int64 = 0
  while current != 1:
    if current mod 2 == 0:
      current = current div 2
    else:
      current = 3 * current + 1
    steps += 1
  steps
