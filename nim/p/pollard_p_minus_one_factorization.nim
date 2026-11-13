const SmallPrimes: array[18, int64] = [2'i64, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61]

proc gcdI64(leftInput, rightInput: int64): int64 =
  var left = leftInput
  var right = rightInput
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc powModI64(baseInput, exponentInput, modulus: int64): int64 =
  var result = 1'i64
  var base = baseInput mod modulus
  var exponent = exponentInput
  while exponent > 0:
    if (exponent and 1) != 0: result = (result * base) mod modulus
    base = (base * base) mod modulus
    exponent = exponent shr 1
  result

proc pollard_p_minus_one_factorization*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "pollard_p_minus_one_factorization".} =
  if input == nil or length != 3: return -1
  let number = input[0]
  let bound = input[1]
  let initial = input[2]
  if number < 2 or number > 1_000_000_000 or bound < 2 or bound > 64 or initial < 1 or initial >= number: return -1
  var divisor = gcdI64(initial, number)
  if divisor > 1: return divisor
  var state = initial
  for prime in SmallPrimes:
    if prime > bound: break
    var exponent = prime
    while exponent <= bound div prime: exponent *= prime
    state = powModI64(state, exponent, number)
    divisor = gcdI64(abs(state - 1), number)
    if divisor > 1: return (if divisor < number: divisor else: 0)
  0
