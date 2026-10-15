module snell_law

import math

const invalid_result = -1.0e300
const half_pi = 1.5707963267948966

@[export: 'snell_law']
pub fn snell_law(n1 f64, n2 f64, theta1 f64) f64 {
	if math.is_nan(n1) || math.is_nan(n2) || math.is_nan(theta1) ||
		n1 < 0.5 || n1 > 2.5 || n2 < 0.5 || n2 > 2.5 || theta1 < -half_pi || theta1 > half_pi {
		return invalid_result
	}
	ratio := n1 / n2
	sin_theta2 := ratio * math.sin(theta1)
	if math.abs(sin_theta2) > 1.0 { return invalid_result }
	return math.asin(sin_theta2)
}
