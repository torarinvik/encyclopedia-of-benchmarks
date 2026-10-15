## Future value of an annuity due using the pinned source formula.
import std/math

proc annuity_due_future_value*(payment, periods, rate: float64): float64 {.cdecl, exportc: "annuity_due_future_value".} =
  let annuity_factor = (pow(1.0 + rate, periods) - 1.0) / rate
  payment * annuity_factor * (1.0 + rate)
