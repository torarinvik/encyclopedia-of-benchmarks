module annuity_due_future_value

import math

// Future value of an annuity due using the pinned source formula.
@[export: 'annuity_due_future_value']
pub fn annuity_due_future_value(payment f64, periods f64, rate f64) f64 {
	annuity_factor := (math.pow(1.0 + rate, periods) - 1.0) / rate
	return payment * annuity_factor * (1.0 + rate)
}
