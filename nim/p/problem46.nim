const MaxOddComposite = 99_999'i64

proc isPrime(number: int64): bool =
  if number < 2: return false
  if number < 4: return true
  if number mod 2 == 0 or number mod 3 == 0: return false
  var divisor = 5'i64
  while divisor <= number div divisor:
    if number mod divisor == 0 or number mod (divisor + 2) == 0: return false
    divisor += 6
  true

proc findFirstCounterexample(): int64 =
  var candidate = 3'i64
  while candidate <= MaxOddComposite:
    if not isPrime(candidate):
      var represented = false
      var square = 0'i64
      while 2 * square * square <= candidate:
        if isPrime(candidate - 2 * square * square):
          represented = true
          break
        square += 1
      if not represented: return candidate
    candidate += 2
  -1

proc problem46*(placeholder: int64): int64 {.cdecl, exportc: "problem46".} =
  if placeholder != 0: return -1
  findFirstCounterexample()
