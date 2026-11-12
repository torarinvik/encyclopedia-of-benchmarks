const
  MaxLength = 64
  MaxNttSize = 128
  MaxInputLength = 2 + 2 * MaxLength + 1
  MaxResultLength = 2 * MaxLength - 1
  P0 = 998244353'i64
  P1 = 985661441'i64
  P2 = 943718401'i64
  P3 = 935329793'i64
  P4 = 918552577'i64

proc powerMod(baseValue, exponentValue, modulus: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod modulus
    base = base * base mod modulus
    exponent = exponent shr 1
  result

proc transform(values: var array[MaxNttSize, int64], n: int,
    modulus, primitiveRoot: int64, inverse: bool) =
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
    var root = powerMod(primitiveRoot, (modulus - 1) div int64(stage), modulus)
    if inverse: root = powerMod(root, modulus - 2, modulus)
    var start = 0
    while start < n:
      var factor = 1'i64
      for offset in 0 ..< stage div 2:
        let left = values[start + offset]
        let right = values[start + offset + stage div 2] * factor mod modulus
        values[start + offset] = (left + right) mod modulus
        values[start + offset + stage div 2] = (left - right + modulus) mod modulus
        factor = factor * root mod modulus
      start += stage
    stage = stage shl 1
  if inverse:
    let scale = powerMod(int64(n), modulus - 2, modulus)
    for i in 0 ..< n: values[i] = values[i] * scale mod modulus

proc convolutionResidues(input: ptr UncheckedArray[int64], n, m, transformLength: int,
    modulus, primitiveRoot: int64, residuesOut: var array[MaxResultLength, int64]) =
  var a: array[MaxNttSize, int64]
  var b: array[MaxNttSize, int64]
  for i in 0 ..< n:
    a[i] = int64(cast[uint64](input[2 + i]) mod uint64(modulus))
  for i in 0 ..< m:
    b[i] = int64(cast[uint64](input[2 + n + i]) mod uint64(modulus))
  transform(a, transformLength, modulus, primitiveRoot, false)
  transform(b, transformLength, modulus, primitiveRoot, false)
  for i in 0 ..< transformLength: a[i] = a[i] * b[i] mod modulus
  transform(a, transformLength, modulus, primitiveRoot, true)
  for i in 0 ..< n + m - 1: residuesOut[i] = a[i]

proc positiveDelta(value, partial, modulus: int64): int64 =
  let delta = value - partial
  if delta < 0: delta + modulus else: delta

proc storeU64Le(output: ptr UncheckedArray[uint8], offset: int, value: uint64) =
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((value shr (8 * byte)) and 255'u64)

proc convolution_mod_2_64*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "convolution_mod_2_64".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > MaxLength or mValue < 1 or mValue > MaxLength: return -1
  let n = int(nValue)
  let m = int(mValue)
  if length != csize_t(2 + n + m): return -1
  let resultLength = n + m - 1
  var transformLength = 1
  while transformLength < resultLength: transformLength = transformLength shl 1
  let outputBytes = 8 * resultLength
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var r0, r1, r2, r3, r4: array[MaxResultLength, int64]
  convolutionResidues(input, n, m, transformLength, P0, 3, r0)
  convolutionResidues(input, n, m, transformLength, P1, 3, r1)
  convolutionResidues(input, n, m, transformLength, P2, 7, r2)
  convolutionResidues(input, n, m, transformLength, P3, 3, r3)
  convolutionResidues(input, n, m, transformLength, P4, 5, r4)

  let p01P2 = (P0 mod P2) * (P1 mod P2) mod P2
  let p01P3 = (P0 mod P3) * (P1 mod P3) mod P3
  let p01P4 = (P0 mod P4) * (P1 mod P4) mod P4
  let p012P3 = p01P3 * (P2 mod P3) mod P3
  let p012P4 = p01P4 * (P2 mod P4) mod P4
  let p0123P4 = p012P4 * (P3 mod P4) mod P4
  let inv0P1 = powerMod(P0 mod P1, P1 - 2, P1)
  let inv01P2 = powerMod(p01P2, P2 - 2, P2)
  let inv012P3 = powerMod(p012P3, P3 - 2, P3)
  let inv0123P4 = powerMod(p0123P4, P4 - 2, P4)
  for i in 0 ..< resultLength:
    let t0 = r0[i]
    let t1 = positiveDelta(r1[i], t0 mod P1, P1) * inv0P1 mod P1
    let x01P2 = (r0[i] mod P2 + (P0 mod P2) * t1) mod P2
    let t2 = positiveDelta(r2[i], x01P2, P2) * inv01P2 mod P2
    let x012P3 = (r0[i] mod P3 + (P0 mod P3) * t1 + p01P3 * t2) mod P3
    let t3 = positiveDelta(r3[i], x012P3, P3) * inv012P3 mod P3
    let x0123P4 = (r0[i] mod P4 + (P0 mod P4) * t1 + p01P4 * t2 + p012P4 * t3) mod P4
    let t4 = positiveDelta(r4[i], x0123P4, P4) * inv0123P4 mod P4
    let value = uint64(t0) + uint64(P0) * uint64(t1)
      + uint64(P0) * uint64(P1) * uint64(t2)
      + uint64(P0) * uint64(P1) * uint64(P2) * uint64(t3)
      + uint64(P0) * uint64(P1) * uint64(P2) * uint64(P3) * uint64(t4)
    storeU64Le(output, 8 * i, value)
  int64(outputBytes)
