package olver_backward_recurrence_boundary_value

import "core:c"
import "core:math"

MAX_PARSEABLE_INPUT_LENGTH :: 53
MAX_NMAX :: 12

finite :: proc(value: f64) -> bool {
	return math.is_finite(value)
}

exact_integer :: proc(value: f64, low, high: i64) -> (i64, bool) {
	if !finite(value) || value < f64(low) || value > f64(high) || f64(i64(value)) != value do return 0, false
	return i64(value), true
}

@(export)
olver_backward_recurrence_boundary_value :: proc "c" (input: [^]f64,
	input_length: c.size_t, output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 8 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	for i: c.size_t = 0; i < input_length; i += 1 { if !finite(input[i]) do return -1 }
	m, valid_m := exact_integer(input[0], 1, 8)
	nmax, valid_n := exact_integer(input[1], 1, MAX_NMAX)
	if !valid_m || !valid_n || m > nmax || input_length != c.size_t(4+4*nmax) do return -1
	if input[2] < 9.094947017729282e-13 || input[2] > 0.5 || math.abs(input[3]) > 16 do return -1
	for i: i64 = 0; i < nmax; i += 1 {
		if math.abs(input[4+i]) < 0.0625 || math.abs(input[4+i]) > 16 ||
			math.abs(input[4+nmax+i]) > 16 || math.abs(input[4+2*nmax+i]) > 16 ||
			math.abs(input[4+3*nmax+i]) > 16 do return -1
	}
	if output == nil || output_capacity < c.size_t(m+2) do return -2
	var p: [14]f64 = {}
	var e: [13]f64 = {}
	var w: [13]f64 = {}
	p[1] = 1
	e[0] = input[3]
	for n: i64 = 1; n <= m; n += 1 {
		a := input[4+n-1]
		b := input[4+nmax+n-1]
		cc := input[4+2*nmax+n-1]
		d := input[4+3*nmax+n-1]
		p[n+1] = (b*p[n]-cc*p[n-1])/a
		e[n] = (cc*e[n-1]-d*p[n])/a
		if !finite(p[n+1]) || !finite(e[n]) do return -3
	}
	for n: i64 = 1; n <= m; n += 1 {
		product := p[n]*p[n+1]
		if product == 0 || !finite(product) || !finite(e[n]/product) do return -3
	}
	minimum := math.abs(e[1] / (p[1] * p[2]))
	for n: i64 = 2; n <= m; n += 1 {
		ratio := math.abs(e[n]/(p[n]*p[n+1]))
		if ratio < minimum do minimum = ratio
	}
	threshold := input[2]*minimum
	endpoint: i64 = 0
	for n: i64 = m; n <= nmax; n += 1 {
		if n > m {
			a := input[4+n-1]
			b := input[4+nmax+n-1]
			cc := input[4+2*nmax+n-1]
			d := input[4+3*nmax+n-1]
			p[n+1] = (b*p[n]-cc*p[n-1])/a
			e[n] = (cc*e[n-1]-d*p[n])/a
			if !finite(p[n+1]) || !finite(e[n]) do return -3
		}
		product := p[n]*p[n+1]
		if product == 0 || !finite(product) do return -3
		ratio := math.abs(e[n]/product)
		if !finite(ratio) do return -3
		if ratio <= threshold { endpoint = n; break }
	}
	if endpoint == 0 do return -3
	w[endpoint] = 0
	for n := endpoint-1; n >= 0; n -= 1 {
		w[n] = (p[n]*w[n+1]+e[n])/p[n+1]
		if !finite(w[n]) do return -3
	}
	output[0] = f64(endpoint)
	for i: i64 = 0; i <= m; i += 1 { output[i+1] = w[i] }
	return m+2
}
