// PolyBench/C trmm kernel, bounded port. Ohio State Software Distribution License: see benchmarks/t/trmm/LICENSE.txt.

package trmm

import "core:c"
import "core:math"

MAX_M :: 8
MAX_N :: 8

@(export)
trmm :: proc "c" (input: [^]f64, length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	m_value, n_value := input[0], input[1]
	if m_value != m_value || n_value != n_value || math.trunc(m_value) != m_value || math.trunc(n_value) != n_value ||
		m_value < 1.0 || m_value > f64(MAX_M) || n_value < 1.0 || n_value > f64(MAX_N) do return -1
	m, n := int(m_value), int(n_value)
	required := m*n
	if output == nil || capacity < c.size_t(required) do return -2
	var a: [MAX_M*MAX_M]f64
	var b: [MAX_M*MAX_N]f64
	for i := 0; i < m; i += 1 {
		for j := 0; j < i; j += 1 { a[i*m+j] = f64((i+j)%m)/f64(m) }
		a[i*m+i] = 1.0
		for j := 0; j < n; j += 1 { b[i*n+j] = f64((n+i-j)%n)/f64(n) }
	}
	for i := 0; i < m; i += 1 { for j := 0; j < n; j += 1 {
		for k := i+1; k < m; k += 1 { b[i*n+j] += a[k*m+i]*b[k*n+j] }
		b[i*n+j] *= 1.5
	} }
	var staged: [MAX_M*MAX_N]f64
	for i := 0; i < required; i += 1 { staged[i] = b[i] }
	for i := 0; i < required; i += 1 { output[i] = staged[i] }
	return i64(required)
}
