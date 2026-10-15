## Ordinary annuity future value using the pinned source formula.
import std/math

proc ordinary_annuity_future_value*(term_payment, number_of_payments, term_interest_rate: float64): float64 {.cdecl, exportc: "ordinary_annuity_future_value".} =
  let annuity_factor = (pow(1.0 + term_interest_rate, number_of_payments) - 1.0) / term_interest_rate
  term_payment * annuity_factor
