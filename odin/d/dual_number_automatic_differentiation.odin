package dual_number_automatic_differentiation

MAX_POWER :: 8
INVALID_RESULT :: -1.0e300

@(export)
dual_number_automatic_differentiation :: proc "c" (position, power, order: f64) -> f64 {
	if !(position >= -1.0 && position <= 1.0) || !(power >= 0.0 && power <= f64(MAX_POWER)) ||
		!(order >= 0.0 && order <= f64(MAX_POWER)) do return INVALID_RESULT
	exponent := int(power)
	derivative_order := int(order)
	if power != f64(exponent) || order != f64(derivative_order) || derivative_order > exponent do return INVALID_RESULT

	coefficients: [MAX_POWER+1]f64
	coefficients[0] = 1.0
	for step:=0; step<exponent; step+=1 {
		next: [MAX_POWER+1]f64
		next[0] = coefficients[0] * position
		for degree:=1; degree<=step+1; degree+=1 {
			next[degree] = coefficients[degree] * position + coefficients[degree-1]
		}
		coefficients = next
	}
	result := coefficients[derivative_order]
	for factor:=2; factor<=derivative_order; factor+=1 { result *= f64(factor) }
	return result
}
