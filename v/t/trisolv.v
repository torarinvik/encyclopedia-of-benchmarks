module trisolv

import math

const max_n = 40

@[export: 'trisolv']
pub fn trisolv(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length != 1 { return -1 }
	unsafe {
		n_value := input[0]
		if !n_value.is_finite() || math.trunc(n_value) != n_value || n_value < 1.0 || n_value > f64(max_n) { return -1 }
		n := int(n_value)
		if output == nil || capacity < usize(n) { return -2 }
		mut lower := [max_n][max_n]f64{}
		mut b := [max_n]f64{}
		mut x := [max_n]f64{}
		for i in 0 .. n {
			b[i] = f64(i)
			for j in 0 .. i + 1 { lower[i][j] = f64(i + n - j + 1) * 2.0 / f64(n) }
		}
		for i in 0 .. n {
			x[i] = b[i]
			for j in 0 .. i { x[i] -= lower[i][j] * x[j] }
			x[i] /= lower[i][i]
		}
		for i in 0 .. n { output[i] = x[i] }
		return i64(n)
	}
}
