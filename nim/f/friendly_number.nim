proc sumDivisors(number: uint64): int64 =
  var divisor = 1'u64
  while divisor * divisor <= number:
    if number mod divisor == 0:
      result += int64(divisor)
      let other = number div divisor
      if other != divisor: result += int64(other)
    inc divisor

proc friendly_number*(a, b: uint64): int64 {.cdecl, exportc: "friendly_number".} =
  if a > 1_000_000 or b > 1_000_000: return -1
  if a == 0 or b == 0: return 0
  let sigmaA = sumDivisors(a)
  let sigmaB = sumDivisors(b)
  if sigmaA * int64(b) == sigmaB * int64(a): 1 else: 0
