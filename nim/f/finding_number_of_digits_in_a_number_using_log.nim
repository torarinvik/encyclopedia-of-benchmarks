import std/math

const MaxAbsValue = 1_000_000'i64

proc finding_number_of_digits_in_a_number_using_log*(value: int64): int64 {.cdecl, exportc: "finding_number_of_digits_in_a_number_using_log".} =
  if value < -MaxAbsValue or value > MaxAbsValue: return -1
  if value == 0: return 0
  int64(floor(log10(abs(float64(value))) + 1.0))
