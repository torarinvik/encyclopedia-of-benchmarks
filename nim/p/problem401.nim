const MaxLimit = 1000'i64
const ModLimit = 1_000_000_000'i64

type Divisors = array[128, int64]

proc contains(value: int64, divisors: Divisors, length: int64): bool =
  for i in 0..<int(length):
    if divisors[i] == value: return true
  false

proc getDivisors(number: int64, divisors: var Divisors): int64 =
  if number == 1:
    divisors[0] = 1
    return 1
  var count = 0'i64
  var divisor = 1'i64
  while divisor * divisor <= number + 1:
    if number mod divisor == 0:
      let quotient = number div divisor
      if not contains(divisor, divisors, count):
        divisors[int(count)] = divisor
        inc count
      if not contains(quotient, divisors, count):
        divisors[int(count)] = quotient
        inc count
    inc divisor
  count

proc sigma2Source(number: int64): int64 =
  var divisors: Divisors
  let count = getDivisors(number, divisors)
  var sum = 0'i64
  for i in 1..<int(count): sum += (divisors[i] * divisors[i]) mod ModLimit
  sum mod ModLimit

proc problem401*(limit: int64): int64 {.cdecl, exportc: "problem401".} =
  if limit < 0 or limit > MaxLimit: return -1
  var sum = 0'i64
  for number in 0'i64..limit: sum += sigma2Source(number)
  sum mod ModLimit
