module magnetic_flux

import math

@[export: 'magnetic_flux']
pub fn magnetic_flux(values &i64, length usize) f64 {
	if length != 3 { return -1.0e300 }
	unsafe {
		magnetic_field := values[0]
		area := values[1]
		angle := values[2]
		if magnetic_field < 0 || magnetic_field > 10000 || area < 0 || area > 10000 || (angle != 0 && angle != 60 && angle != 90 && angle != 120 && angle != 180) { return -1.0e300 }
		pi_value := 3.14159265358979323846
		radians := f64(angle) * (pi_value / 180.0)
		flux := f64(magnetic_field) * f64(area) * math.cos(radians)
		return math.round(flux * 10.0) / 10.0
	}
}
