module equated_monthly_installments

import math

const invalid_result = -1.0e300

@[export: 'equated_monthly_installments']
pub fn equated_monthly_installments(principal f64, rate_per_annum f64, years_to_repay f64) f64 {
	if math.is_nan(principal) || math.is_nan(rate_per_annum) || math.is_nan(years_to_repay) ||
		principal <= 0.0 || principal > 1_000_000.0 || rate_per_annum < 0.0001 || rate_per_annum > 0.2 ||
		years_to_repay < 1.0 || years_to_repay > 30.0 || math.floor(years_to_repay) != years_to_repay {
		return invalid_result
	}
	monthly_rate := rate_per_annum / 12.0
	payments := years_to_repay * 12.0
	factor := math.pow(1.0 + monthly_rate, payments)
	return principal * monthly_rate * factor / (factor - 1.0)
}
