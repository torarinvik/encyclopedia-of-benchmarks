## Encode the first n palindrome primes as little-endian u32 values.
proc palindrome_prime*(n: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "palindrome_prime".} =
  if n > 16: return -1
  if n <= 0: return 0
  let required = int(n) * 4
  if output == nil or outputCapacity < csize_t(required): return -2

  output[0] = 2
  output[1] = 0
  output[2] = 0
  output[3] = 0
  var count = 1
  var candidate = 3
  while count < int(n):
    var remaining = candidate
    var reversed = 0
    while remaining > 0:
      reversed = reversed * 10 + remaining mod 10
      remaining = remaining div 10
    var prime = candidate >= 2
    var divisor = 2
    while prime and divisor <= candidate div divisor:
      if candidate mod divisor == 0:
        prime = false
      inc divisor
    if candidate == reversed and prime:
      let position = count * 4
      output[position] = uint8(candidate and 255)
      output[position + 1] = uint8((candidate shr 8) and 255)
      output[position + 2] = uint8((candidate shr 16) and 255)
      output[position + 3] = uint8((candidate shr 24) and 255)
      inc count
    candidate += 2
  int64(required)
