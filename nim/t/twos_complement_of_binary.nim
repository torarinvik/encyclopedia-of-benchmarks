const MaxBinaryDigitNumeral = 1_111_111_111_111_111'i64

proc twos_complement_of_binary*(value: int64): int64
    {.cdecl, exportc: "twos_complement_of_binary".} =
  if value < 0 or value > MaxBinaryDigitNumeral: return -1
  if value == 0: return 0

  var remaining = value
  while remaining > 0:
    let digit = remaining mod 10
    if digit != 0 and digit != 1: return -1
    remaining = remaining div 10

  remaining = value
  var reversed = 0'i64
  var width = 0'i64
  while remaining > 0 and remaining mod 10 == 0:
    reversed = reversed * 10 + remaining mod 10
    remaining = remaining div 10
    inc width
  if remaining > 0:
    reversed = reversed * 10 + remaining mod 10
    remaining = remaining div 10
    inc width
  while remaining > 0:
    let digit = remaining mod 10
    reversed = reversed * 10 + (if digit == 1: 0'i64 else: 1'i64)
    remaining = remaining div 10
    inc width

  var result = 0'i64
  while width > 0:
    result = result * 10 + reversed mod 10
    reversed = reversed div 10
    dec width
  result
