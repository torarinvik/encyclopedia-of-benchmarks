## Check whether the square ends with the original nonnegative integer.
proc addMod(left, right, modulus: uint64): uint64 =
  if left >= modulus - right: left - (modulus - right) else: left + right

proc multiplyMod(left, right, modulus: uint64): uint64 =
  var factor = left
  var multiplier = right
  var result: uint64 = 0
  while multiplier != 0:
    if (multiplier and 1) != 0: result = addMod(result, factor, modulus)
    multiplier = multiplier shr 1
    if multiplier != 0: factor = addMod(factor, factor, modulus)
  result

proc automorphic_number*(n: int64): int64 {.cdecl, exportc: "automorphic_number".} =
  if n < 0: return 0
  let number = uint64(n)
  var modulus = 10'u64
  var digits = number
  while digits >= 10:
    digits = digits div 10
    modulus *= 10
  if multiplyMod(number, number, modulus) == number: 1 else: 0
