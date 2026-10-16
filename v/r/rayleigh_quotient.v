module rayleigh_quotient

import math

@[export: 'rayleigh_quotient']
pub fn rayleigh_quotient(values &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if isnil(values) || length < 1 || length > 273 { return -1 }
		for i in 0 .. int(length) {
			if values[i] != values[i] { return -1 }
		}
		n_value := values[0]
		if n_value < 1.0 || n_value > 16.0 || math.floor(n_value) != n_value { return -1 }
		n := int(n_value)
		if length != usize(1 + n*n + n) { return -1 }
		matrix_start := 1
		vector_start := 1 + n*n

		for row in 0 .. n {
			for col in 0 .. n {
				value := values[matrix_start + row*n + col]
				if value < -1000.0 || value > 1000.0 { return -1 }
				if col > row && value != values[matrix_start + col*n + row] { return -1 }
			}
		}

		mut denominator := f64(0)
		for i in 0 .. n {
			value := values[vector_start + i]
			if value < -100.0 || value > 100.0 { return -1 }
			denominator += value * value
		}
		if denominator <= 0.0 { return -1 }

		mut numerator := f64(0)
		for col in 0 .. n {
			mut v_star_dot := f64(0)
			for row in 0 .. n {
				v_star_dot += values[vector_start + row] * values[matrix_start + row*n + col]
			}
			numerator += v_star_dot * values[vector_start + col]
		}
		quotient := numerator / denominator
		if isnil(output) || capacity < 1 { return -2 }
		output[0] = quotient
		return 1
	}
}
