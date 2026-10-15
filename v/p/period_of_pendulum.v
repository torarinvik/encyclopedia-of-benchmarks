module period_of_pendulum

import math

const pi_value = 3.141592653589793238462643383279502884

@[export: 'period_of_pendulum']
pub fn period_of_pendulum(values &i64, length usize) f64 {
	if length != 1 { return -1.0e300 }
	pendulum_length := unsafe { values[0] }
	if pendulum_length < 0 || pendulum_length > 1000 { return -1.0e300 }
	root := math.pow(f64(pendulum_length) / 9.80665, 0.5)
	return (2.0 * pi_value) * root
}
