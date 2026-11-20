proc sqIsqrt(value, upper: int64): int64 =
  var low = 0'i64
  var high = upper + 1
  while low + 1 < high:
    let middle = low + (high - low) div 2
    if middle * middle <= value: low = middle
    else: high = middle
  low

proc sqGcd(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc sqReverse(number, discriminant, a, p, q, cap: int64): int64 =
  let root = sqIsqrt(q, 1_414_214)
  if root * root != q: return 0
  let quotient = (a - p) div root
  var r = quotient * root + p
  var previousS = root
  var s = (discriminant - r * r) div root
  var step = 0'i64
  while step < cap:
    let nextQuotient = (a + r) div s
    let nextR = nextQuotient * s - r
    if nextR == r:
      let factor = sqGcd(number, r)
      if factor > 1 and factor < number:
        let other = number div factor
        if factor < other: return factor
        return other
      return 0
    let nextS = previousS + nextQuotient * (r - nextR)
    previousS = s
    s = nextS
    r = nextR
    inc step
  0

proc squfof_semiprime_factor*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "squfof_semiprime_factor".} =
  if input == nil or length != 3: return -1
  let number = input[0]
  let forwardCap = input[1]
  let reverseCap = input[2]
  if number < 3 or number > 1_000_000_000_000'i64 or number mod 2 == 0
      or forwardCap < 0 or forwardCap > 256 or reverseCap < 0 or reverseCap > 256: return -1
  let exactRoot = sqIsqrt(number, 1_000_000)
  if exactRoot * exactRoot == number: return exactRoot
  let discriminant = if number mod 4 == 1: 2 * number else: number
  let a = sqIsqrt(discriminant, 1_414_214)
  var previousQ = 1'i64
  var q = discriminant - a * a
  var p = a
  var index = 1'i64
  var step = 0'i64
  while step < forwardCap:
    let quotient = (a + p) div q
    let nextP = quotient * q - p
    let nextQ = previousQ + quotient * (p - nextP)
    previousQ = q
    q = nextQ
    p = nextP
    inc index
    if index mod 2 == 0:
      let factor = sqReverse(number, discriminant, a, p, q, reverseCap)
      if factor != 0: return factor
    inc step
  0
