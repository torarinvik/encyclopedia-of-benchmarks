const MaxDigits = 9

proc isPrime(number: int64): bool =
  if number < 2: return false
  if number < 4: return true
  if number mod 2 == 0 or number mod 3 == 0: return false
  var divisor = 5'i64
  while divisor <= number div divisor:
    if number mod divisor == 0 or number mod (divisor + 2) == 0: return false
    divisor += 6
  true

proc search(digits, depth: int, used: uint16, value: int64): int64 =
  if depth == digits: return if isPrime(value): value else: 0
  var best = 0'i64
  for digit in 1 .. digits:
    let bit = 1'u16 shl digit
    if (used and bit) != 0: continue
    let candidate = search(digits, depth + 1, used or bit, value * 10 + digit.int64)
    if candidate > best: best = candidate
  best

proc problem41*(digits: int64): int64 {.cdecl, exportc: "problem41".} =
  if digits < 1 or digits > MaxDigits.int64: return -1
  search(digits.int, 0, 0, 0)
