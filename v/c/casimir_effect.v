module casimir_effect

import math

@[export: 'casimir_effect']
pub fn casimir_effect(values &i64, length usize) f64 {
	if length != 3 { return -1.0e300 }
	unsafe {
		force_units := values[0]
		area_units := values[1]
		distance_units := values[2]
		if force_units < 0 || force_units > 1000000 || area_units < 0 || area_units > 1000000 || distance_units < 0 || distance_units > 1000000 { return -1.0e300 }
		zero_count := i32(force_units == 0) + i32(area_units == 0) + i32(distance_units == 0)
		if zero_count != 1 { return -1.0e300 }
		force := f64(force_units) * 1.0e-12
		area := f64(area_units) * 1.0e-6
		distance := f64(distance_units) * 1.0e-6
		hbar := 1.054571817e-34
		speed_of_light := 3.0e8
		pi_value := 3.14159265358979323846
		if force_units == 0 { return (hbar * speed_of_light * math.pow(pi_value, 2.0) * area) / (240.0 * math.pow(distance, 4.0)) }
		if area_units == 0 { return (240.0 * force * math.pow(distance, 4.0)) / (hbar * speed_of_light * math.pow(pi_value, 2.0)) }
		return math.pow((hbar * speed_of_light * math.pow(pi_value, 2.0) * area) / (240.0 * force), 0.25)
	}
}
