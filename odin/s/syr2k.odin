package syr2k
import "core:c"

MAX_N :: 8
MAX_M :: 16

@(export, link_name="syr2k")
syr2k :: proc "c" (input: [^]f64, length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	n_value, m_value := input[0], input[1]
	if n_value != n_value || m_value != m_value ||
		n_value < 1.0 || n_value > f64(MAX_N) ||
		m_value < 1.0 || m_value > f64(MAX_M) do return -1
	n, m := int(n_value), int(m_value)
	if f64(n) != n_value || f64(m) != m_value do return -1
	alpha := 1.5
	beta := 1.2
	a: [MAX_N * MAX_M]f64
	b: [MAX_N * MAX_M]f64
	c_values: [MAX_N * MAX_N]f64

	for i := 0; i < n; i += 1 {
		for j := 0; j < m; j += 1 {
			a[i * m + j] = f64((i * j + 1) % n) / f64(n)
			b[i * m + j] = f64((i * j + 2) % m) / f64(m)
		}
	}
	for i := 0; i < n; i += 1 {
		for j := 0; j < n; j += 1 {
			c_values[i * n + j] = f64((i * j + 3) % n) / f64(m)
		}
	}

	for i := 0; i < n; i += 1 {
		for j := 0; j <= i; j += 1 { c_values[i * n + j] *= beta }
		for k := 0; k < m; k += 1 {
			for j := 0; j <= i; j += 1 {
				c_values[i * n + j] += a[j * m + k] * alpha * b[i * m + k] + b[j * m + k] * alpha * a[i * m + k]
			}
		}
	}

	required := n * n
	if output == nil || capacity < c.size_t(required) do return -2
	for index := 0; index < required; index += 1 { output[index] = c_values[index] }
	return i64(required)
}
