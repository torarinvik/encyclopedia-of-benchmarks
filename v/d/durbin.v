module durbin

import math

const max_n = 40

@[export: 'durbin']
pub fn durbin(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length != 1 { return -1 }
	unsafe {
		n_value := input[0]
		if !n_value.is_finite() || math.trunc(n_value) != n_value || n_value < 1.0 || n_value > f64(max_n) { return -1 }
		n := int(n_value)
		if output == nil || capacity < usize(n) { return -2 }
		mut r := [max_n]f64{}
		mut y := [max_n]f64{}
		mut z := [max_n]f64{}
		for i in 0 .. n { r[i] = f64(n + 1 - i) }
		y[0] = -r[0]
		mut beta := 1.0
		mut alpha := -r[0]
		for k in 1 .. n {
			beta = (1.0 - alpha * alpha) * beta
			mut sum := 0.0
			for i in 0 .. k { sum += r[k - i - 1] * y[i] }
			alpha = -(r[k] + sum) / beta
			for i in 0 .. k { z[i] = y[i] + alpha * y[k - i - 1] }
			for i in 0 .. k { y[i] = z[i] }
			y[k] = alpha
		}
		for i in 0 .. n { output[i] = y[i] }
		return i64(n)
	}
}
