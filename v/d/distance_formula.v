module distance_formula

import math

@[export: 'distance_formula']
pub fn distance_formula(values &i64, length usize) f64 {
	if length != 4 { return -1.0e300 }
	for i in 0 .. 4 {
		value := unsafe { values[i] }
		if value < -1000000 || value > 1000000 { return -1.0e300 }
	}
	dx := f64(unsafe { values[2] - values[0] })
	dy := f64(unsafe { values[3] - values[0] })
	return math.sqrt(dx * dx + dy * dy)
}
