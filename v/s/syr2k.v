module syr2k

import math

const max_n = 8
const max_m = 16

@[export: 'syr2k']
pub fn syr2k(input &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		n_value := input[0]
		m_value := input[1]
		if !n_value.is_finite() || !m_value.is_finite() || math.trunc(n_value) != n_value || math.trunc(m_value) != m_value || n_value < 1 || n_value > f64(max_n) || m_value < 1 || m_value > f64(max_m) {
			return -1
		}
		n := int(n_value)
		m := int(m_value)
		alpha := 1.5
		beta := 1.2
		mut a := [128]f64{}
		mut b := [128]f64{}
		mut c := [64]f64{}

		for i in 0 .. n {
			for j in 0 .. m {
				a[i * m + j] = f64((i * j + 1) % n) / f64(n)
				b[i * m + j] = f64((i * j + 2) % m) / f64(m)
			}
		}
		for i in 0 .. n {
			for j in 0 .. n {
				c[i * n + j] = f64((i * j + 3) % n) / f64(m)
			}
		}

		for i in 0 .. n {
			for j in 0 .. (i + 1) { c[i * n + j] *= beta }
			for k in 0 .. m {
				for j in 0 .. (i + 1) {
					c[i * n + j] += a[j * m + k] * alpha * b[i * m + k] + b[j * m + k] * alpha * a[i * m + k]
				}
			}
		}

		required := n * n
		if output == nil || capacity < usize(required) { return -2 }
		for index in 0 .. required { output[index] = c[index] }
		return i64(required)
	}
}
