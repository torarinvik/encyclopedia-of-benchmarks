const
  Modulus = 998_244_353'i64
  MaxN = 8
  MaxM = 8
  NttSize = 32
  MaxInput = 12

type Transform = array[NttSize, int64]

proc modPow(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1

proc ntt(values: var Transform, inverse: bool) =
  var j = 0
  for i in 1 ..< NttSize:
    var bit = NttSize div 2
    while (j and bit) != 0:
      j = j xor bit
      bit = bit shr 1
    j = j xor bit
    if i < j: swap(values[i], values[j])
  var blockSize = 2
  while blockSize <= NttSize:
    var root = modPow(3, (Modulus - 1) div blockSize.int64)
    if inverse: root = modPow(root, Modulus - 2)
    let half = blockSize div 2
    for start in countup(0, NttSize - 1, blockSize):
      var factor = 1'i64
      for offset in 0 ..< half:
        let even = values[start + offset]
        let odd = values[start + offset + half] * factor mod Modulus
        values[start + offset] = (even + odd) mod Modulus
        values[start + offset + half] = (even - odd + Modulus) mod Modulus
        factor = factor * root mod Modulus
    blockSize *= 2
  if inverse:
    let scale = modPow(NttSize.int64, Modulus - 2)
    for value in values.mitems: value = value * scale mod Modulus

proc evaluate(coefficients: ptr UncheckedArray[int64], offset, count: int, x: int64): int64 =
  result = 0
  for degree in countdown(count - 1, 0):
    result = (result * x + coefficients[offset + degree]) mod Modulus

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc multipoint_evaluation_on_geometric_sequence*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "multipoint_evaluation_on_geometric_sequence".} =
  if input.isNil or length < csize_t(5) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > MaxN.int64 or mValue < 1 or mValue > MaxM.int64: return -1
  let n = nValue.int
  let m = mValue.int
  let start = input[2]
  let ratio = input[3]
  if length != csize_t(n + 4) or start < 0 or start >= Modulus or ratio < 0 or ratio >= Modulus: return -1
  for i in 0 ..< n:
    if input[i + 4] < 0 or input[i + 4] >= Modulus: return -1
  let bytes = 8 * m
  if output.isNil or capacity < csize_t(bytes): return -2
  if start == 0:
    for i in 0 ..< m: storeLe(output, 8 * i, input[4])
    return int64(bytes)
  if ratio == 0:
    storeLe(output, 0, evaluate(input, 4, n, start))
    for i in 1 ..< m: storeLe(output, 8 * i, input[4])
    return int64(bytes)

  let inverseRatio = modPow(ratio, Modulus - 2)
  var left, right: Transform
  var startPower = 1'i64
  var inverseChirp = 1'i64
  var inverseRatioPower = 1'i64
  for degree in 0 ..< n:
    left[n - 1 - degree] = input[4 + degree] * startPower mod Modulus * inverseChirp mod Modulus
    startPower = startPower * start mod Modulus
    inverseChirp = inverseChirp * inverseRatioPower mod Modulus
    inverseRatioPower = inverseRatioPower * inverseRatio mod Modulus
  var chirp = 1'i64
  var ratioPower = 1'i64
  for index in 0 ..< n + m - 1:
    right[index] = chirp
    chirp = chirp * ratioPower mod Modulus
    ratioPower = ratioPower * ratio mod Modulus
  ntt(left, false)
  ntt(right, false)
  for i in 0 ..< NttSize: left[i] = left[i] * right[i] mod Modulus
  ntt(left, true)
  inverseChirp = 1
  inverseRatioPower = 1
  for i in 0 ..< m:
    storeLe(output, 8 * i, left[n - 1 + i] * inverseChirp mod Modulus)
    inverseChirp = inverseChirp * inverseRatioPower mod Modulus
    inverseRatioPower = inverseRatioPower * inverseRatio mod Modulus
  int64(bytes)
