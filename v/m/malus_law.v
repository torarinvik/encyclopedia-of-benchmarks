module malus_law

import math

const pi_value = 3.141592653589793238462643383279502884

@[export: 'malus_law']
pub fn malus_law(values &i64, length usize) f64 {
	if length != 2 { return -1.0e300 }
	initial_intensity := unsafe { values[0] }
	angle := unsafe { values[1] }
	if initial_intensity < 0 || initial_intensity > 1000 || angle < 0 || angle > 360 {
		return -1.0e300
	}
	radians := (f64(angle) * pi_value) / 180.0
	cosine := math.cos(radians)
	return f64(initial_intensity) * (cosine * cosine)
}
