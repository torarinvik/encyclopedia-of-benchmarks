// PolyBench/C trmm kernel, bounded port. Ohio State Software Distribution License: see benchmarks/t/trmm/LICENSE.txt.

import math

const max_m = 8
const max_n = 8

@[export: 'trmm']
pub fn trmm(input &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		m_value := input[0]; n_value := input[1]
		if !m_value.is_finite() || !n_value.is_finite() || math.trunc(m_value) != m_value || math.trunc(n_value) != n_value ||
			m_value < 1 || m_value > f64(max_m) || n_value < 1 || n_value > f64(max_n) { return -1 }
		m := int(m_value); n := int(n_value); required := m*n
		if output == nil || capacity < usize(required) { return -2 }
		mut a := [64]f64{}
		mut b := [64]f64{}
		for i in 0 .. m {
			for j in 0 .. i { a[i*m+j] = f64((i+j)%m)/f64(m) }
			a[i*m+i] = 1.0
			for j in 0 .. n { b[i*n+j] = f64((n+i-j)%n)/f64(n) }
		}
		for i in 0 .. m { for j in 0 .. n {
			for k in i+1 .. m { b[i*n+j] += a[k*m+i]*b[k*n+j] }
			b[i*n+j] *= 1.5
		} }
		mut staged := [64]f64{}
		for i in 0 .. required { staged[i] = b[i] }
		for i in 0 .. required { output[i] = staged[i] }
		return i64(required)
	}
}
