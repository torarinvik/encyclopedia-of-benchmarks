module main

import math

const invalid_result = -1.0e300

@[export: 'transformations_2d']
pub fn transformations_2d(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 3 { return invalid_result }
	operation := unsafe { values[0] }
	parameter_micro := unsafe { values[1] }
	component := unsafe { values[2] }
	if operation < 0 || operation > 3 || component < 0 || component > 3 { return invalid_result }

	mut m0 := 0.0
	mut m1 := 0.0
	mut m2 := 0.0
	mut m3 := 0.0
	if operation == 0 {
		if parameter_micro < -1_000_000 || parameter_micro > 1_000_000 { return invalid_result }
		factor := f64(parameter_micro) / 1_000_000.0
		m0 = factor * 1.0
		m1 = factor * 0.0
		m2 = factor * 0.0
		m3 = factor * 1.0
	} else {
		if parameter_micro < -6_283_185 || parameter_micro > 6_283_185 { return invalid_result }
		angle := f64(parameter_micro) / 1_000_000.0
		c := math.cos(angle)
		s := math.sin(angle)
		if operation == 1 {
			m0 = c
			m1 = -s
			m2 = s
			m3 = c
		} else {
			cs := c * s
			if operation == 2 {
				m0 = c * c
				m1 = cs
				m2 = cs
				m3 = s * s
			} else {
				m0 = 2.0 * c - 1.0
				m1 = 2.0 * cs
				m2 = 2.0 * cs
				m3 = 2.0 * s - 1.0
			}
		}
	}
	if component == 0 { return m0 }
	if component == 1 { return m1 }
	if component == 2 { return m2 }
	return m3
}
