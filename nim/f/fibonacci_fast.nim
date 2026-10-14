## Compute Fibonacci numbers by portable 64-bit fast doubling.
proc fibonacciFast*(input: int64): int64 {.cdecl, exportc: "fibonacci_fast".} =
  if input < 0 or input > 92: return -1
  let n = uint64(input)
  var bit = 1'u64
  while bit <= n div 2: bit = bit shl 1
  var current = 0'u64
  var next = 1'u64
  while bit != 0:
    let even = current * (2 * next - current)
    let odd = current * current + next * next
    if (n and bit) != 0:
      current = odd
      next = even + odd
    else:
      current = even
      next = odd
    bit = bit shr 1
  int64(current)
