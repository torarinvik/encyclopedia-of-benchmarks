const
  MaxModulus = 1_000_000_000'i64
  MaxLength = 3

proc reciprocity(numerator, denominator: int64): int64 =
  var a = numerator
  var n = denominator
  var sign = 1'i64
  while a != 0:
    while (a and 1) == 0:
      a = a div 2
      if n mod 8 == 3 or n mod 8 == 5: sign = -sign
    if a mod 4 == 3 and n mod 4 == 3: sign = -sign
    let oldA = a
    a = n
    n = oldA
    a = a mod n
  if n == 1: sign else: 0

proc jacobi_symbol*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "jacobi_symbol".} =
  if input == nil or length != 2: return -1
  let numerator = input[0]
  let denominator = input[1]
  if denominator < 1 or denominator > MaxModulus or (denominator and 1) == 0: return -1
  if numerator < 0 or numerator >= denominator: return -1
  reciprocity(numerator, denominator) + 1
