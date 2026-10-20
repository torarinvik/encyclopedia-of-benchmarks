# New bounded port based on AtCoder Library convolution semantics (CC0); see benchmarks/n/number_theoretic_transform/LICENSE.txt.
const Modulus = 998244353'i64

proc modPow(aValue, exponentValue: int64): int64 =
  var a = aValue
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = (result * a) mod Modulus
    a = (a * a) mod Modulus
    exponent = exponent shr 1
  result

proc number_theoretic_transform*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "number_theoretic_transform".} =
  if input.isNil or inputLength < 2 or inputLength > 65: return -1
  let nValue = input[0]
  if nValue < 1 or nValue > 64 or (nValue and (nValue - 1)) != 0 or inputLength != (nValue + 1).csize_t: return -1
  let n = int(nValue)
  var a: array[64, int64]
  for i in 0 ..< n:
    if input[i + 1] < 0 or input[i + 1] >= Modulus: return -1
    a[i] = input[i + 1]
  if output.isNil or outputCapacity < (4 * n).csize_t: return -2
  var j = 0
  for i in 1 ..< n:
    var bit = n shr 1
    while (j and bit) != 0:
      j = j xor bit
      bit = bit shr 1
    j = j xor bit
    if i < j: swap(a[i], a[j])
  var length = 2
  while length <= n:
    let step = modPow(3, (Modulus - 1) div int64(length))
    var base = 0
    while base < n:
      var w = 1'i64
      for k in 0 ..< length div 2:
        let u = a[base + k]
        let v = (a[base + k + length div 2] * w) mod Modulus
        a[base + k] = (u + v) mod Modulus
        a[base + k + length div 2] = (u - v + Modulus) mod Modulus
        w = (w * step) mod Modulus
      base += length
    length *= 2
  for i in 0 ..< n:
    let x = uint32(a[i])
    for b in 0 ..< 4: output[4 * i + b] = uint8((x shr (8 * b)) and 0xff)
  int64(4 * n)
