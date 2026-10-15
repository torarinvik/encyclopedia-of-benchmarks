module newtons_law_of_gravitation

import math

const gravitational_constant = 6.6743e-11

@[export: 'newtons_law_of_gravitation']
pub fn newtons_law_of_gravitation(values &i64, length usize) f64 {
	if length != 4 { return -1.0e300 }
	target := unsafe { values[0] }
	a := unsafe { values[1] }
	b := unsafe { values[2] }
	c_value := unsafe { values[3] }
	if target < 0 || target > 3 || a < 1 || a > 1000 || b < 1 || b > 1000 || c_value < 1 || c_value > 1000 {
		return -1.0e300
	}
	if target == 0 { return gravitational_constant * (f64(a) * f64(b)) / (f64(c_value) * f64(c_value)) }
	if target == 1 { return f64(a) * (f64(c_value) * f64(c_value)) / (gravitational_constant * f64(b)) }
	if target == 2 { return f64(a) * (f64(c_value) * f64(c_value)) / (gravitational_constant * f64(b)) }
	return math.sqrt((gravitational_constant * (f64(b) * f64(c_value))) / f64(a))
}
