package clenshaw_curtis_quadrature

import "core:c"
import "core:math"

MAX_PARSEABLE_INPUT_LENGTH :: 19
PI_PINNED :: 3.14159265358979323846264338327950288

exact_integer :: proc(value: f64, low, high: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(low) || value > f64(high) do return false
	return f64(i64(value)) == value
}

compute :: proc(n: i64, samples: [^]f64) -> f64 {
	mut result := 0.0
	for k: i64 = 0; k <= n; k += 1 {
		mut inner := 0.0
		for j: i64 = 1; j <= n/2; j += 1 {
			bj := if j == n/2 do 1.0 else 2.0
			denominator := f64(4*j*j-1)
			angle := (((2.0*f64(j))*f64(k))*PI_PINNED)/f64(n)
			term := (bj/denominator)*math.cos_f64(angle)
			inner += term
		}
		gk := if k == 0 || k == n do 1.0 else 2.0
		weight := (gk/f64(n))*(1.0-inner)
		result += weight*samples[k+1]
	}
	return result
}

@(export)
clenshaw_curtis_quadrature :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 4 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if !exact_integer(input[0],2,16) do return -1
	n := i64(input[0])
	if n%2 != 0 || input_length != c.size_t(n+2) do return -1
	for i: c.size_t = 1; i < input_length; i += 1 {
		if math.is_nan(input[i]) || math.is_inf(input[i]) || math.abs(input[i]) > 1000.0 do return -1
	}
	if output == nil || output_capacity < 1 do return -2
	value := compute(n,input)
	if math.is_nan(value) || math.is_inf(value) do return -1
	output[0] = value
	return 1
}
