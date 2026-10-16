module to_polar_angle_degrees

import math

const invalid_result = -1.0e300
const pi_value = 3.141592653589793238462643383279502884

@[export: 'to_polar_angle_degrees']
pub fn to_polar_angle_degrees(x f64, y f64) f64 {
	if x != x || y != y || x < -1000000.0 || x > 1000000.0 ||
		y < -1000000.0 || y > 1000000.0 || (x == 0.0 && y == 0.0) { return invalid_result }
	theta := if x >= 0.0 { math.atan(y / x) } else { math.atan(y / x) + pi_value }
	return theta * (180.0 / pi_value)
}
