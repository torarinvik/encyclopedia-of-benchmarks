const Modulus = 998_244_353'i64
const MaxLength = 256
const MaxNttSize = 512
const MaxInputLength = 2 + 2 * MaxLength

proc powerMod(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0: result = (result * base) mod Modulus
    base = (base * base) mod Modulus
    exponent = exponent shr 1

proc transform(values: var array[MaxNttSize, int64], n: int, inverse: bool) =
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
    var root = powerMod(3, (Modulus - 1) div int64(stage))
    if inverse: root = powerMod(root, Modulus - 2)
    var start = 0
    while start < n:
      var factor = 1'i64
      for offset in 0 ..< (stage div 2):
        let left = values[start + offset]
        let right = (values[start + offset + stage div 2] * factor) mod Modulus
        values[start + offset] = (left + right) mod Modulus
        values[start + offset + stage div 2] = (left - right + Modulus) mod Modulus
        factor = (factor * root) mod Modulus
      start += stage
    stage *= 2
  if inverse:
    let scale = powerMod(int64(n), Modulus - 2)
    for i in 0 ..< n: values[i] = (values[i] * scale) mod Modulus

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc convolution_mod*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "convolution_mod".} =
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

  var a: array[MaxNttSize, int64]
  var b: array[MaxNttSize, int64]
  for i in 0 ..< n: a[i] = input[2 + i]
  for i in 0 ..< m: b[i] = input[2 + n + i]
  transform(a, transformLength, false)
  transform(b, transformLength, false)
  for i in 0 ..< transformLength: a[i] = (a[i] * b[i]) mod Modulus
  transform(a, transformLength, true)
  for i in 0 ..< resultLength: storeI64Le(output, 8 * i, a[i])
  int64(outputBytes)
