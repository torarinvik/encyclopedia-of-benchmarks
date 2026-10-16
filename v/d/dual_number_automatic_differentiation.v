module dual_number_automatic_differentiation

const max_power = 8
const invalid_result = -1.0e300

@[export: 'dual_number_automatic_differentiation']
pub fn dual_number_automatic_differentiation(position f64, power f64, order f64) f64 {
	if !(position >= -1.0 && position <= 1.0) || !(power >= 0.0 && power <= max_power) ||
		!(order >= 0.0 && order <= max_power) { return invalid_result }
	exponent := int(power)
	derivative_order := int(order)
	if power != f64(exponent) || order != f64(derivative_order) || derivative_order > exponent {
		return invalid_result
	}

	mut coefficients := [max_power + 1]f64{}
	coefficients[0] = 1.0
	for step in 0 .. exponent {
		mut next := [max_power + 1]f64{}
		next[0] = coefficients[0] * position
		mut degree := 1
		for degree <= step + 1 {
			next[degree] = coefficients[degree] * position + coefficients[degree - 1]
			degree++
		}
		coefficients = next
	}
	mut result := coefficients[derivative_order]
	mut factor := 2
	for factor <= derivative_order {
		result *= f64(factor)
		factor++
	}
	return result
}
