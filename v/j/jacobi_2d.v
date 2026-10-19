module jacobi_2d

import math

const max_n = 30
const max_tsteps = 20

@[export: 'jacobi_2d']
pub fn jacobi_2d(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	unsafe {
		n_value := input[0]
		steps_value := input[1]
		if !n_value.is_finite() || !steps_value.is_finite() || math.trunc(n_value) != n_value || math.trunc(steps_value) != steps_value || n_value < 1.0 || n_value > f64(max_n) || steps_value < 0.0 || steps_value > f64(max_tsteps) { return -1 }
		n := int(n_value)
		tsteps := int(steps_value)
		count := n * n
		if output == nil || capacity < usize(count) { return -2 }
		mut a := [max_n][max_n]f64{}
		mut b := [max_n][max_n]f64{}
		for i in 0 .. n {
			for j in 0 .. n {
				a[i][j] = (f64(i) * f64(j + 2) + 2.0) / f64(n)
				b[i][j] = (f64(i) * f64(j + 3) + 3.0) / f64(n)
			}
		}
		for _ in 0 .. tsteps {
			if n > 2 {
				for i in 1 .. (n - 1) {
					for j in 1 .. (n - 1) { b[i][j] = 0.2 * (a[i][j] + a[i][j - 1] + a[i][j + 1] + a[i + 1][j] + a[i - 1][j]) }
				}
				for i in 1 .. (n - 1) {
					for j in 1 .. (n - 1) { a[i][j] = 0.2 * (b[i][j] + b[i][j - 1] + b[i][j + 1] + b[i + 1][j] + b[i - 1][j]) }
				}
			}
		}
		for i in 0 .. n {
			for j in 0 .. n { output[i * n + j] = a[i][j] }
		}
		return i64(count)
	}
}
