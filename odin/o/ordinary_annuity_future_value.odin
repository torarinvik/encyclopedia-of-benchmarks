package ordinary_annuity_future_value

import "core:math"

// Ordinary annuity future value using the pinned source formula.
@(export)
ordinary_annuity_future_value :: proc "c" (term_payment, number_of_payments, term_interest_rate: f64) -> f64 {
	annuity_factor := (math.pow_f64(1.0 + term_interest_rate, number_of_payments) - 1.0) / term_interest_rate
	return term_payment * annuity_factor
}
