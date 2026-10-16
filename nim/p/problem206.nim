const Start = 138_902_663'i64
const Minimum = 101_010_103'i64

proc problem206IsSquareForm(valueInput: int64): bool =
  var value = valueInput
  var digit = 9'i64
  while value > 0:
    if value mod 10 != digit: return false
    value = value div 100
    dec digit
  true

proc problem206*(unused: int64): int64 {.cdecl, exportc: "problem206".} =
  if unused != 0: return -1
  var candidate = Start
  while candidate >= Minimum:
    if problem206IsSquareForm(candidate * candidate): return candidate * 10
    candidate -= (if candidate mod 10 == 3: 6'i64 else: 4'i64)
  -1
