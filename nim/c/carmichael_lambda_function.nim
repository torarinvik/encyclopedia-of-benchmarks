const
  MaxN = 1024'i64
  MaxParseableLength = 2

proc gcdI64(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc lcmI64(left, right: int64): int64 =
  (left div gcdI64(left, right)) * right

proc primePowerLambda(prime: int64, exponent: int, power: int64): int64 =
  if prime == 2:
    if exponent == 1: return 1
    if exponent == 2: return 2
    return power div 4
  (power div prime) * (prime - 1)

proc factorizationLambda(n: int64): int64 =
  if n == 1: return 1
  var remaining = n
  var result = 1'i64
  var prime = 2'i64
  while prime * prime <= remaining:
    if remaining mod prime != 0:
      if prime == 2: prime = 3 else: prime += 2
      continue
    var exponent = 0
    var power = 1'i64
    while remaining mod prime == 0:
      remaining = remaining div prime
      power *= prime
      inc exponent
    result = lcmI64(result, primePowerLambda(prime, exponent, power))
    if prime == 2: prime = 3 else: prime += 2
  if remaining > 1: result = lcmI64(result, remaining - 1)
  result

proc carmichael_lambda_function*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "carmichael_lambda_function".} =
  if input == nil or length < 1 or length > csize_t(MaxParseableLength): return -1
  let n = input[0]
  if n < 1 or n > MaxN or length != 1: return -1
  factorizationLambda(n)
