package syrk

import "core:c"

MAX_N :: 8
MAX_M :: 16

@(export, link_name="syrk")
syrk :: proc "c" (input: [^]f64, length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	n_value := input[0]
	m_value := input[1]
	if n_value != n_value || m_value != m_value ||
		n_value < 1.0 || n_value > f64(MAX_N) || m_value < 1.0 || m_value > f64(MAX_M) do return -1
	n := int(n_value)
	m := int(m_value)
	if f64(n) != n_value || f64(m) != m_value do return -1
	alpha := 1.5
	beta := 1.2
	a: [MAX_N * MAX_M]f64
	c: [MAX_N * MAX_N]f64

	for i := 0; i < n; i += 1 {
		for k := 0; k < m; k += 1 {
			a[i * m + k] = f64((i * k + 1) % n) / f64(n)
		}
	}
	for i := 0; i < n; i += 1 {
		for j := 0; j < n; j += 1 {
			c[i * n + j] = f64((i * j + 2) % m) / f64(m)
		}
	}

	for i := 0; i < n; i += 1 {
		for j := 0; j <= i; j += 1 { c[i * n + j] *= beta }
		for k := 0; k < m; k += 1 {
			for j := 0; j <= i; j += 1 {
				c[i * n + j] += alpha * a[i * m + k] * a[j * m + k]
			}
		}
	}

	required := n * n
	if output == nil || capacity < c.size_t(required) do return -2
	for index := 0; index < required; index += 1 { output[index] = c[index] }
	return i64(required)
}
