proc isPrime(value: int64): bool =
  if value < 2: return false
  if value == 2 or value == 3: return true
  if value mod 2 == 0 or value mod 3 == 0: return false
  var divisor = 5'i64
  while divisor <= value div divisor:
    if value mod divisor == 0 or value mod (divisor + 2) == 0: return false
    divisor += 6
  true

proc isTruncatablePrime(value: int64): bool =
  if not isPrime(value): return false
  var power = 10'i64
  while power < value:
    if not isPrime(value div power) or not isPrime(value mod power): return false
    power *= 10
  true

proc problem37*(ignored: int64): int64 {.cdecl, exportc: "problem37".} =
  if ignored != 0: return -1
  var found = 0
  var sum = 0'i64
  var candidate = 13'i64
  while candidate <= 1_000_000 and found < 11:
    if isTruncatablePrime(candidate):
      sum += candidate
      inc found
    candidate += 2
  if found == 11: sum else: -1
