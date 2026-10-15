import std/math

const MaxAbsValue = 1_000_000.0
const InvalidResult = -1.0e300

proc finding_number_of_digits_in_a_number_using_log*(value: float64): float64
    {.cdecl, exportc: "finding_number_of_digits_in_a_number_using_log".} =
  if not (value >= -MaxAbsValue and value <= MaxAbsValue): return InvalidResult
  if value == 0.0: return 0.0
  floor(log10(abs(value)) + 1.0)
