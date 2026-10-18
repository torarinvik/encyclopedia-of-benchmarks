const MinN = 2'i64
const MaxN = 46_340'i64
const MaxSteps = 4_096'i64

proc javaRemainder(value, modulus: int64): int64 =
  if value < 0: -((-value) mod modulus) else: value mod modulus

proc nextValue(value, modulus: int64): int64 =
  javaRemainder(value * value - 1, modulus)

proc gcdNonnegative(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc pollardRhoJava*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "pollard_rho_java".} =
  if input == nil or length != 2: return -1
  let n = input[0]
  let stepLimit = input[1]
  if n < MinN or n > MaxN or stepLimit < 1 or stepLimit > MaxSteps: return -1

  var x = 2'i64
  var y = 2'i64
  for _ in 0'i64 ..< stepLimit:
    x = nextValue(x, n)
    y = nextValue(nextValue(y, n), n)
    let difference = if x >= y: x - y else: y - x
    let divisor = gcdNonnegative(difference, n)
    if divisor == 1: continue
    if divisor == n: return 0
    return divisor
  -2
