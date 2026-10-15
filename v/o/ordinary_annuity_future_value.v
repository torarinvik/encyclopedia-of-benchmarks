module ordinary_annuity_future_value

import math

// Ordinary annuity future value using the pinned source formula.
@[export: 'ordinary_annuity_future_value']
pub fn ordinary_annuity_future_value(term_payment f64, number_of_payments f64, term_interest_rate f64) f64 {
	annuity_factor := (math.pow(1.0 + term_interest_rate, number_of_payments) - 1.0) / term_interest_rate
	return term_payment * annuity_factor
}
