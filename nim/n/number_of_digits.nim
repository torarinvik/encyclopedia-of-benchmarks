## Count base-10 digits in the magnitude, including for low(int64).
proc number_of_digits*(value: int64): int64 {.cdecl, exportc: "number_of_digits".} =
  var magnitude: uint64
  if value < 0:
    magnitude = uint64(-(value + 1)) + 1'u64
  else:
    magnitude = uint64(value)
  var digits = 1'i64
  while magnitude >= 10'u64:
    magnitude = magnitude div 10'u64
    inc digits
  digits
