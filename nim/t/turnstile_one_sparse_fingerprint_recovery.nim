const Modulus = 1_000_000_007'i64

proc powerMod(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0: result = (result * base) mod Modulus
    base = (base * base) mod Modulus
    exponent = exponent shr 1

proc turnstile_one_sparse_fingerprint_recovery*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "turnstile_one_sparse_fingerprint_recovery".} =
  if input == nil or length < 3 or length > 260: return -1
  let n = input[0]
  let q = input[1]
  let base = input[2]
  if n < 1 or n > 64 or q < 0 or q > 128 or base < 1 or base >= Modulus or
      length != csize_t(3 + 2 * q): return -1
  var mass, weighted, fingerprint: int64 = 0
  for i in 0 ..< int(q):
    let index = input[3 + 2 * i]
    let delta = input[4 + 2 * i]
    if index < 0 or index >= n or delta < -1000 or delta > 1000: return -1
    mass += delta
    weighted += delta * index
    fingerprint = (fingerprint + delta * powerMod(base, index)) mod Modulus
    if fingerprint < 0: fingerprint += Modulus
  if mass == 0 or weighted mod mass != 0: return 0
  let index = weighted div mass
  if index < 0 or index >= n: return 0
  var expected = (mass * powerMod(base, index)) mod Modulus
  if expected < 0: expected += Modulus
  if fingerprint == expected: return index + 1
  return 0
