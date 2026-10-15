module speed_of_sound

import math

@[export: 'speed_of_sound']
pub fn speed_of_sound(values &i64, length usize) f64 {
	if length != 2 { return -1.0e300 }
	density := unsafe { values[0] }
	bulk_modulus := unsafe { values[1] }
	if density < 1 || density > 1000 || bulk_modulus < 1 || bulk_modulus > 1_000_000_000 {
		return -1.0e300
	}
	return math.pow(f64(bulk_modulus) / f64(density), 0.5)
}
