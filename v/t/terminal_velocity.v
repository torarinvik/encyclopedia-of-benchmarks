module terminal_velocity

import math

@[export: 'terminal_velocity']
pub fn terminal_velocity(values &i64, length usize) f64 {
	if length != 4 { return -1.0e300 }
	mass := unsafe { values[0] }
	density := unsafe { values[1] }
	area := unsafe { values[2] }
	drag_coefficient := unsafe { values[3] }
	if mass < 1 || mass > 1000 || density < 1 || density > 1000 || area < 1 || area > 1000 || drag_coefficient < 1 || drag_coefficient > 1000 {
		return -1.0e300
	}
	numerator := (2.0 * f64(mass)) * 9.80665
	denominator := (f64(density) * f64(area)) * f64(drag_coefficient)
	return math.sqrt(numerator / denominator)
}
