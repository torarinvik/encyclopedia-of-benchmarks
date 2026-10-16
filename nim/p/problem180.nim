const MaxOrder = 35'i64
const HashCapacity = 524_288
const BigBase = 10_000'i64
const BigLimbs = 8

proc gcdI64(leftInput, rightInput: int64): int64 =
  var left = leftInput
  var right = rightInput
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc integerSqrt(value: int64): int64 =
  if value <= 0: return 0
  var root = value
  var next = (root + value div root) div 2
  while next < root:
    root = next
    next = (root + value div root) div 2
  root

proc insertFraction(nums, dens: var seq[int64], numerator, denominator: int64): bool =
  var index = int(((numerator mod HashCapacity.int64()) * 1009 + denominator mod HashCapacity.int64()) mod HashCapacity.int64())
  while dens[index] != 0:
    if nums[index] == numerator and dens[index] == denominator: return false
    index = (index + 1) mod HashCapacity
  nums[index] = numerator
  dens[index] = denominator
  true

proc recordSum(nums, dens: var seq[int64], xn, xd, yn, yd, znInput, zdInput, order: int64) =
  if znInput <= 0 or zdInput <= 0: return
  var zn = znInput
  var zd = zdInput
  var divisor = gcdI64(zn, zd)
  zn = zn div divisor
  zd = zd div divisor
  if zn >= zd or zd > order: return
  let sumNumerator = xn * yd * zd + yn * xd * zd + zn * xd * yd
  let sumDenominator = xd * yd * zd
  divisor = gcdI64(sumNumerator, sumDenominator)
  discard insertFraction(nums, dens, sumNumerator div divisor, sumDenominator div divisor)

proc problem180*(order: int64): int64 {.cdecl, exportc: "problem180".} =
  if order < 1 or order > MaxOrder: return -1
  var numerators = newSeq[int64](HashCapacity)
  var denominators = newSeq[int64](HashCapacity)

  for xn in 1'i64..order:
    for xd in (xn + 1)..order:
      if gcdI64(xn, xd) != 1: continue
      for yn in 1'i64..order:
        for yd in (yn + 1)..order:
          if gcdI64(yn, yd) != 1 or xn * yd > yn * xd: continue
          var zn = xn * yd + xd * yn
          var zd = xd * yd
          recordSum(numerators, denominators, xn, xd, yn, yd, zn, zd, order)

          var squareNum = xn*xn*yd*yd + xd*xd*yn*yn
          var squareDen = xd*xd*yd*yd
          var rootNum = integerSqrt(squareNum)
          var rootDen = integerSqrt(squareDen)
          if rootNum*rootNum == squareNum and rootDen*rootDen == squareDen:
            recordSum(numerators, denominators, xn, xd, yn, yd, rootNum, rootDen, order)

          zn = xn * yn
          zd = xd * yn + xn * yd
          recordSum(numerators, denominators, xn, xd, yn, yd, zn, zd, order)

          squareNum = xn*xn*yn*yn
          squareDen = xd*xd*yn*yn + xn*xn*yd*yd
          rootNum = integerSqrt(squareNum)
          rootDen = integerSqrt(squareDen)
          if rootNum*rootNum == squareNum and rootDen*rootDen == squareDen:
            recordSum(numerators, denominators, xn, xd, yn, yd, rootNum, rootDen, order)

  var common = 1'i64
  for factor in 2'i64..order: common = common div gcdI64(common, factor) * factor
  var total: array[BigLimbs, int64]
  for i in 0..<HashCapacity:
    if denominators[i] != 0:
      if common mod denominators[i] != 0: return -1
      var carry = numerators[i] * (common div denominators[i])
      var limb = 0
      while carry > 0:
        let current = total[limb] + carry
        total[limb] = current mod BigBase
        carry = current div BigBase
        inc limb

  var remainder = 0'i64
  for i in countdown(BigLimbs - 1, 0): remainder = (remainder * BigBase + total[i]) mod common
  let divisor = gcdI64(remainder, common)
  remainder = 0
  for i in countdown(BigLimbs - 1, 0):
    let current = remainder * BigBase + total[i]
    total[i] = current div divisor
    remainder = current mod divisor
  var numerator = 0'i64
  for i in countdown(BigLimbs - 1, 0):
    let limb = total[i]
    if numerator > (high(int64) - limb) div BigBase: return -1
    numerator = numerator * BigBase + limb
  let denominator = common div divisor
  if numerator > high(int64) - denominator: return -1
  numerator + denominator
