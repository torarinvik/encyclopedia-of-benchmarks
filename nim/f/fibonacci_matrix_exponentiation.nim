const MaxIndex = 9007199254740991.0
const MaxModulus = 4294967295.0

func multiplySum(a, b, c, d, modulus: uint64): uint64 =
  ((a * b) mod modulus + (c * d) mod modulus) mod modulus

proc fibonacci_matrix_exponentiation*(indexInput, modulusInput: float64): float64
    {.cdecl, exportc: "fibonacci_matrix_exponentiation".} =
  if not (indexInput >= 1.0 and indexInput <= MaxIndex) or
      not (modulusInput >= 1.0 and modulusInput <= MaxModulus): return -1.0
  let index = uint64(indexInput)
  let modulus = uint64(modulusInput)
  if float64(index) != indexInput or float64(modulus) != modulusInput: return -1.0

  var r00 = 1'u64 mod modulus
  var r01 = 0'u64
  var r10 = 0'u64
  var r11 = 1'u64 mod modulus
  var t00 = 0'u64
  var t01 = 1'u64 mod modulus
  var t10 = 1'u64 mod modulus
  var t11 = 1'u64 mod modulus
  var exponent = index - 1'u64
  while exponent > 0'u64:
    if exponent mod 2'u64 == 1'u64:
      let n00 = multiplySum(r00, t00, r01, t10, modulus)
      let n01 = multiplySum(r00, t01, r01, t11, modulus)
      let n10 = multiplySum(r10, t00, r11, t10, modulus)
      let n11 = multiplySum(r10, t01, r11, t11, modulus)
      r00 = n00; r01 = n01; r10 = n10; r11 = n11
      dec exponent
    else:
      let n00 = multiplySum(t00, t00, t01, t10, modulus)
      let n01 = multiplySum(t00, t01, t01, t11, modulus)
      let n10 = multiplySum(t10, t00, t11, t10, modulus)
      let n11 = multiplySum(t10, t01, t11, t11, modulus)
      t00 = n00; t01 = n01; t10 = n10; t11 = n11
      exponent = exponent div 2'u64
  float64((r00 + r10) mod modulus)
