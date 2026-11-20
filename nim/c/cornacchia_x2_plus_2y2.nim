const
  MaxPrime = 1_000_000'i64
  MaxLength = 3
  PackBase = 1024'i64

proc isPrime(value: int64): bool =
  if value < 2: return false
  var divisor = 2'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    if divisor == 2: divisor = 3 else: divisor += 2
  true

proc isqrt(value: int64): int64 =
  var low = 0'i64
  var high = 1001'i64
  while low + 1 < high:
    let middle = (low + high) div 2
    if middle * middle <= value: low = middle else: high = middle
  low

proc cornacchia_x2_plus_2y2*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "cornacchia_x2_plus_2y2".} =
  if input == nil or length != 2: return -1
  let prime = input[0]
  let root = input[1]
  if prime < 3 or prime > MaxPrime or (prime and 1) == 0 or root < 1 or root > prime div 2: return -1
  if not isPrime(prime) or (root * root + 2) mod prime != 0: return -1

  var previous = prime
  var current = root
  let limit = isqrt(prime)
  while current > limit:
    let remainder = previous mod current
    previous = current
    current = remainder
  let x = current
  let numerator = prime - x * x
  if numerator <= 0 or numerator mod 2 != 0: return -1
  let ySquared = numerator div 2
  let y = isqrt(ySquared)
  if y <= 0 or y * y != ySquared or x * x + 2 * y * y != prime: return -1
  x * PackBase + y
