package tanh_sinh_double_exponential_quadrature

import "core:c"
import "core:math"

MAX_PARSEABLE_INPUT_LENGTH :: 3
PI_PINNED :: 3.14159265358979323846264338327950288

exact_integer :: proc(value: f64, low, high: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(low) || value > f64(high) do return false
	return f64(i64(value)) == value
}

integrate :: proc(function_id, p: i64) -> f64 {
	h := 1.0 / f64(1 << p)
	half_pi := PI_PINNED / 2.0
	limit := 3 * (1 << p)
	mut total := 0.0
	for j: i64 = -limit; j <= limit; j += 1 {
		t := f64(j) * h
		exp_t := math.exp_f64(t)
		exp_minus_t := math.exp_f64(-t)
		sinh_t := (exp_t-exp_minus_t)*0.5
		cosh_t := (exp_t+exp_minus_t)*0.5
		u := half_pi*sinh_t
		abs_u := if u < 0.0 do -u else u
		q := math.exp_f64(-2.0*abs_u)
		one_plus_q := 1.0+q
		sech_squared := (4.0*q)/(one_plus_q*one_plus_q)
		magnitude_x := (1.0-q)/one_plus_q
		x := if u >= 0.0 do magnitude_x else -magnitude_x
		jacobian := (half_pi*cosh_t)*sech_squared
		mut sample: f64 = 0.0
		if function_id == 0 do sample = 1.0
		else if function_id == 1 do sample = x*x
		else if function_id == 2 do sample = 1.0/math.sqrt_f64(sech_squared)
		else if u >= 0.0 do sample = 1.0/math.sqrt_f64((2.0*q)/one_plus_q)
		else do sample = 1.0/math.sqrt_f64(2.0/one_plus_q)
		transformed := sample*jacobian
		total += h*transformed
	}
	return total
}

@(export)
tanh_sinh_double_exponential_quadrature :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if input_length != 2 || !exact_integer(input[0],0,3) || !exact_integer(input[1],2,4) do return -1
	if output == nil || output_capacity < 1 do return -2
	value := integrate(i64(input[0]),i64(input[1]))
	if math.is_nan(value) || math.is_inf(value) do return -1
	output[0] = value
	return 1
}
