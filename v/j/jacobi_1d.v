module jacobi_1d

import math

const max_n = 30
const max_tsteps = 20

@[export: 'jacobi_1d']
pub fn jacobi_1d(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	unsafe {
		n_value := input[0]
		steps_value := input[1]
		if !n_value.is_finite() || !steps_value.is_finite() || math.trunc(n_value) != n_value || math.trunc(steps_value) != steps_value || n_value < 1.0 || n_value > f64(max_n) || steps_value < 0.0 || steps_value > f64(max_tsteps) { return -1 }
		n := int(n_value)
		tsteps := int(steps_value)
		if output == nil || capacity < usize(n) { return -2 }
		mut a := [max_n]f64{}
		mut b := [max_n]f64{}
		for i in 0 .. n {
			a[i] = (f64(i) + 2.0) / f64(n)
			b[i] = (f64(i) + 3.0) / f64(n)
		}
		for _ in 0 .. tsteps {
			if n > 2 {
				for i in 1 .. n - 1 { b[i] = 0.33333 * (a[i - 1] + a[i] + a[i + 1]) }
				for i in 1 .. n - 1 { a[i] = 0.33333 * (b[i - 1] + b[i] + b[i + 1]) }
			}
		}
		for i in 0 .. n { output[i] = a[i] }
		return i64(n)
	}
}
