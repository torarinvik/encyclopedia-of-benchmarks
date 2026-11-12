const Modulus = 998_244_353'i64
const MaxN = 32

proc modularPower(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1
  result

proc bernoulli_number*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "bernoulli_number".} =
  if input.isNil or length != csize_t(1): return -1
  let n64 = input[0]
  if n64 < 0 or n64 > MaxN.int64: return -1
  let n = int(n64)
  let outputBytes = 4 * (n + 1)
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var inverse: array[MaxN + 2, int64]
  var bernoulli: array[MaxN + 1, int64]
  inverse[1] = 1
  bernoulli[0] = 1
  if n > 0:
    for i in 2..(n + 1):
      inverse[i] = modularPower(i.int64, Modulus - 2)
    for m in 1..n:
      var choose = 1'i64
      var total = 0'i64
      for k in 0..<m:
        total = (total + choose * bernoulli[k]) mod Modulus
        choose = choose * (m + 1 - k).int64 mod Modulus * inverse[k + 1] mod Modulus
      bernoulli[m] = ((Modulus - total) mod Modulus) * inverse[m + 1] mod Modulus

  for i in 0..n:
    let value = uint32(bernoulli[i])
    output[4 * i] = uint8(value and 0xff'u32)
    output[4 * i + 1] = uint8((value shr 8) and 0xff'u32)
    output[4 * i + 2] = uint8((value shr 16) and 0xff'u32)
    output[4 * i + 3] = uint8((value shr 24) and 0xff'u32)
  int64(outputBytes)
