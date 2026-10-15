## Check whether n cubed ends with the decimal digits of n.
proc trimorphic_number*(number: int64): int64 {.cdecl, exportc: "trimorphic_number".} =
  if number < 0 or number > 2_000_000: return -1
  var modulus = 10'i64
  var digits = number
  while digits >= 10:
    digits = digits div 10
    modulus *= 10
  let cube = number * number * number
  if cube mod modulus == number: 1 else: 0
