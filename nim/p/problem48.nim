const modulus: int64 = 10_000_000_000

proc problem48*(ignored: int64): int64 {.cdecl, exportc: "problem48".} =
  if ignored != 0: return -1
  var total: int64 = 0
  var base: int64 = 1
  while base <= 1000:
    var term: int64 = 1
    var exponent: int64 = 0
    while exponent < base:
      term = (term * base) mod modulus
      inc exponent
    total = (total + term) mod modulus
    inc base
  total
