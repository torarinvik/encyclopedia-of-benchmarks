const
  tableSize = 65_536
  tableMask = tableSize - 1
  maxModulus = 1_000_000_000'i64

proc gcdU64(left, right: uint64): uint64 =
  var a = left
  var b = right
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc ceilSqrt(value: uint64): uint64 =
  var low = 1'u64
  var high = 31_623'u64
  while low < high:
    let middle = low + (high - low) div 2
    if middle * middle >= value: high = middle else: low = middle + 1
  low

proc powMod(baseValue, exponentValue, modulus: uint64): uint64 =
  var base = baseValue
  var exponent = exponentValue
  var accumulated = 1'u64 mod modulus
  while exponent != 0:
    if (exponent and 1) != 0: accumulated = (accumulated * base) mod modulus
    base = (base * base) mod modulus
    exponent = exponent shr 1
  accumulated

proc inverseMod(value, modulus: uint64): int64 =
  var oldR = int64(value)
  var r = int64(modulus)
  var oldT = 1'i64
  var t = 0'i64
  while r != 0:
    let quotient = oldR div r
    let nextR = oldR - quotient * r
    let nextT = oldT - quotient * t
    oldR = r; r = nextR; oldT = t; t = nextT
  if oldR != 1: return -1
  oldT = oldT mod int64(modulus)
  if oldT < 0: oldT += int64(modulus)
  oldT

proc insertBaby(keys: var seq[uint64], steps: var seq[uint32], key: uint64, step: uint32) =
  var slot = int(key and uint64(tableMask))
  while steps[slot] != 0:
    if keys[slot] == key: return
    slot = (slot + 1) and tableMask
  keys[slot] = key
  steps[slot] = step + 1

proc findBaby(keys: seq[uint64], steps: seq[uint32], key: uint64): int64 =
  var slot = int(key and uint64(tableMask))
  while steps[slot] != 0:
    if keys[slot] == key: return int64(steps[slot] - 1)
    slot = (slot + 1) and tableMask
  -1

proc coprimeLog(x, y, modulus: uint64): int64 =
  if y == 1'u64 mod modulus: return 0
  let width = ceilSqrt(modulus)
  var keys = newSeq[uint64](tableSize)
  var steps = newSeq[uint32](tableSize)
  var residue = 1'u64 mod modulus
  for step in 0'u64 ..< width:
    insertBaby(keys, steps, residue, uint32(step))
    residue = (residue * x) mod modulus
  let inverse = inverseMod(x, modulus)
  if inverse < 0: return -1
  let giantFactor = powMod(uint64(inverse), width, modulus)
  var giant = y
  var block = 0'u64
  while block * width <= modulus:
    let baby = findBaby(keys, steps, giant)
    if baby >= 0:
      let answer = block * width + uint64(baby)
      return if answer <= modulus: int64(answer) else: -1
    giant = (giant * giantFactor) mod modulus
    inc block
  -1

proc extendedLog(x, initialY, initialModulus: uint64): int64 =
  var y = initialY
  var modulus = initialModulus
  if modulus == 1: return 0
  var accumulator = 1'u64
  var added = 0'u64
  while gcdU64(x, modulus) > 1:
    let divisor = gcdU64(x, modulus)
    if y == accumulator: return int64(added)
    if y mod divisor != 0: return -1
    y = y div divisor
    modulus = modulus div divisor
    accumulator = (accumulator * (x div divisor)) mod modulus
    inc added
    if modulus == 1: return int64(added)
  let inverse = inverseMod(accumulator, modulus)
  if inverse < 0: return -1
  let target = (y * uint64(inverse)) mod modulus
  let remaining = coprimeLog(x mod modulus, target, modulus)
  if remaining < 0: return -1
  int64(added) + remaining

proc discrete_logarithm_mod*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "discrete_logarithm_mod".} =
  if values == nil or length != 3: return -1
  let x = values[0]
  let y = values[1]
  let modulus = values[2]
  if x < 0 or y < 0 or modulus < 1 or modulus > maxModulus or x >= modulus or y >= modulus:
    return -1
  extendedLog(uint64(x), uint64(y), uint64(modulus))
