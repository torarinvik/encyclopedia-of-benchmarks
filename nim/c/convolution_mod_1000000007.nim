const Modulus = 1_000_000_007'i64
const P1 = 998_244_353'i64
const P2 = 1_004_535_809'i64
const P3 = 469_762_049'i64
const MaxLength = 64
const NttSize = 128
const MaxResult = 2 * MaxLength - 1
const MaxInputLength = 2 + 2 * MaxLength

proc powerMod(baseValue, exponentValue, modulus: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0: result = (result * base) mod modulus
    base = (base * base) mod modulus
    exponent = exponent shr 1

proc transform(values: var array[NttSize, int64], n: int, modulus: int64, inverse: bool) =
  var j = 0
  for i in 1 ..< n:
    var bit = n shr 1
    while (j and bit) != 0:
      j = j xor bit
      bit = bit shr 1
    j = j xor bit
    if i < j: swap(values[i], values[j])
  var stage = 2
  while stage <= n:
    var root = powerMod(3, (modulus - 1) div int64(stage), modulus)
    if inverse: root = powerMod(root, modulus - 2, modulus)
    var start = 0
    while start < n:
      var factor = 1'i64
      for offset in 0 ..< (stage div 2):
        let left = values[start + offset]
        let right = (values[start + offset + stage div 2] * factor) mod modulus
        values[start + offset] = (left + right) mod modulus
        values[start + offset + stage div 2] = (left - right + modulus) mod modulus
        factor = (factor * root) mod modulus
      start += stage
    stage *= 2
  if inverse:
    let scale = powerMod(int64(n), modulus - 2, modulus)
    for i in 0 ..< n: values[i] = (values[i] * scale) mod modulus

proc convolutionResidues(input: ptr UncheckedArray[int64], n, m, transformLength,
    resultLength: int, modulus: int64, output: var array[MaxResult, int64]) =
  var a: array[NttSize, int64]
  var b: array[NttSize, int64]
  for i in 0 ..< n: a[i] = input[2 + i] mod modulus
  for i in 0 ..< m: b[i] = input[2 + n + i] mod modulus
  transform(a, transformLength, modulus, false)
  transform(b, transformLength, modulus, false)
  for i in 0 ..< transformLength: a[i] = (a[i] * b[i]) mod modulus
  transform(a, transformLength, modulus, true)
  for i in 0 ..< resultLength: output[i] = a[i]

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc convolution_mod_1000000007*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "convolution_mod_1000000007".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > MaxLength or mValue < 1 or mValue > MaxLength: return -1
  let n = int(nValue)
  let m = int(mValue)
  if length != csize_t(2 + n + m): return -1
  for i in 0 ..< n + m:
    let coefficient = input[2 + i]
    if coefficient < 0 or coefficient >= Modulus: return -1
  let resultLength = n + m - 1
  var transformLength = 1
  while transformLength < resultLength: transformLength *= 2
  let outputBytes = 8 * resultLength
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var r1, r2, r3: array[MaxResult, int64]
  convolutionResidues(input, n, m, transformLength, resultLength, P1, r1)
  convolutionResidues(input, n, m, transformLength, resultLength, P2, r2)
  convolutionResidues(input, n, m, transformLength, resultLength, P3, r3)
  let inv1 = powerMod(P1 mod P2, P2 - 2, P2)
  let p12mod3 = (P1 mod P3) * (P2 mod P3) mod P3
  let inv12 = powerMod(p12mod3, P3 - 2, P3)
  let p1mod = P1 mod Modulus
  let p12mod = p1mod * (P2 mod Modulus) mod Modulus
  for i in 0 ..< resultLength:
    let t1 = ((r2[i] - r1[i] mod P2 + P2) mod P2) * inv1 mod P2
    let x12 = (r1[i] mod P3 + (P1 mod P3) * (t1 mod P3)) mod P3
    let t2 = ((r3[i] - x12 + P3) mod P3) * inv12 mod P3
    let value = (r1[i] + p1mod * (t1 mod Modulus) + p12mod * (t2 mod Modulus)) mod Modulus
    storeI64Le(output, 8 * i, value)
  int64(outputBytes)
