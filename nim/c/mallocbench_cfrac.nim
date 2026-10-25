## Clean-room bounded CFRAC profile based on the published
## Morrison-Brillhart continued-fraction factorization method.
## No code from the restricted arbitrary-precision package is included.
const MaxBase = 10
const MaxIterations = 48
const MaxPrime = 10000'u32

proc gcd(aValue, bValue: uint64): uint64 =
  var a = aValue
  var b = bValue
  while b != 0:
    let r = a mod b
    a = b
    b = r
  a

proc modPow(baseValue, exponentValue, modulus: uint64): uint64 =
  var base = baseValue mod modulus
  var exponent = exponentValue
  var result = 1'u64
  while exponent != 0:
    if (exponent and 1) != 0: result = (result * base) mod modulus
    base = (base * base) mod modulus
    exponent = exponent shr 1
  result

proc isPrime(value: uint32): bool =
  if value < 2: return false
  var divisor = 2'u32
  while uint64(divisor) * uint64(divisor) <= uint64(value):
    if value mod divisor == 0: return false
    inc divisor
  true

proc makeBase(n: uint64, requested: int, base: var array[MaxBase, uint32]): bool =
  var count = 1
  base[0] = 2
  var p = 3'u32
  while p <= MaxPrime and count < requested:
    if isPrime(p):
      let residue = modPow(n mod uint64(p), uint64((p - 1) div 2), uint64(p))
      # Upstream selects residue 0 too; this profile rejects that domain case.
      if residue == 0: return false
      if residue == 1:
        base[count] = p
        inc count
    p += 2
  count == requested

proc mallocbench_cfrac*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "mallocbench_cfrac".} =
  if input.isNil or length != 3: return -1
  let nValue = input[0]
  let baseValue = input[1]
  let iterationValue = input[2]
  if nValue < 15 or nValue > 1_000_000 or (nValue and 1) == 0 or
      baseValue < 2 or baseValue > MaxBase or iterationValue < 1 or iterationValue > MaxIterations: return -1
  let n = uint64(nValue)
  var root = 0'u64
  while root + 1 <= n div (root + 1): inc root
  if root * root == n: return -1
  let baseCount = int(baseValue)
  let iterationLimit = int(iterationValue)
  var base: array[MaxBase, uint32]
  if not makeBase(n, baseCount, base): return -1

  var basisVector: array[MaxBase + 1, uint64]
  var basisCombo: array[MaxBase + 1, uint64]
  var basisUsed: array[MaxBase + 1, bool]
  var relationA: array[MaxIterations, uint64]
  var relationExp: array[MaxIterations, array[MaxBase, uint8]]
  var relationCount = 0
  var u = int64(2 * root)
  var previousU = u
  var qValue = 0'i64
  var qDenominator = 1'i64
  var previousDenominator = int64(n - root * root)
  var aValue = 1'i64
  var previousA = int64(root)
  var sign = 0'u64

  for _ in 0 ..< iterationLimit:
    let oldA = aValue
    aValue = (qValue * aValue + previousA) mod nValue
    previousA = oldA
    let oldDenominator = qDenominator
    qDenominator = qValue * (previousU - u) + previousDenominator
    previousDenominator = oldDenominator
    previousU = u
    if qDenominator <= 0: return nValue
    qValue = 1
    var remainder = u - qDenominator
    if remainder >= qDenominator:
      qValue = u div qDenominator
      remainder = u mod qDenominator
    u = int64(2 * root) - remainder
    sign = sign xor 1
    if qDenominator == 1: return nValue

    var residual = uint64(qDenominator)
    var exponents: array[MaxBase, uint8]
    for j in 0 ..< baseCount:
      while residual mod uint64(base[j]) == 0:
        residual = residual div uint64(base[j])
        inc exponents[j]
    if residual != 1: continue
    relationA[relationCount] = uint64(aValue)
    relationExp[relationCount] = exponents
    var vector = sign
    for j in 0 ..< baseCount:
      if (exponents[j] and 1) != 0: vector = vector or (1'u64 shl (j + 1))
    var combination = 1'u64 shl relationCount
    inc relationCount

    var inserted = false
    for bit in 0 .. baseCount:
      if (vector and (1'u64 shl bit)) == 0: continue
      if basisUsed[bit]:
        vector = vector xor basisVector[bit]
        combination = combination xor basisCombo[bit]
      else:
        basisUsed[bit] = true
        basisVector[bit] = vector
        basisCombo[bit] = combination
        inserted = true
        break
    if not inserted:
      var x = 1'u64
      var exponentSum: array[MaxBase, uint64]
      for i in 0 ..< relationCount:
        if (combination and (1'u64 shl i)) == 0: continue
        x = (x * relationA[i]) mod n
        for j in 0 ..< baseCount: exponentSum[j] += uint64(relationExp[i][j])
      var y = 1'u64
      for j in 0 ..< baseCount:
        y = (y * modPow(uint64(base[j]), exponentSum[j] div 2, n)) mod n
      let minus = gcd(if x >= y: x - y else: y - x, n)
      if minus > 1 and minus < n: return int64(minus)
      let plus = gcd(x + y, n)
      if plus > 1 and plus < n: return int64(plus)
  nValue
