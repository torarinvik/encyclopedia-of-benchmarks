package equated_monthly_installments

import "core:math"

INVALID_RESULT :: f64 = -1.0e300

@(export)
equated_monthly_installments :: proc "c" (principal, rate_per_annum, years_to_repay: f64) -> f64 {
	if math.isnan_f64(principal) || math.isnan_f64(rate_per_annum) || math.isnan_f64(years_to_repay) ||
		principal <= 0.0 || principal > 1_000_000.0 || rate_per_annum < 0.0001 || rate_per_annum > 0.2 ||
		years_to_repay < 1.0 || years_to_repay > 30.0 || math.floor_f64(years_to_repay) != years_to_repay do return INVALID_RESULT
	monthly_rate := rate_per_annum / 12.0
	payments := years_to_repay * 12.0
	factor := math.pow_f64(1.0 + monthly_rate, payments)
	return principal * monthly_rate * factor / (factor - 1.0)
}
