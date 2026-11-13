package adaptive_simpson_quadrature

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 6

sample :: proc(function_id: i64, x: f64) -> f64 {
	if function_id == 0 do return x*x*x*x
	if function_id == 1 do return math.sin_f64(x)
	return 1.0 / (1.0 + x*x)
}

simpson :: proc(a, b, fa, fm, fb: f64) -> f64 {
	return (b-a)*(fa+4.0*fm+fb)/6.0
}

refine :: proc(function_id: i64, a, b, fa, fm, fb, whole, tolerance: f64, depth: i64) -> f64 {
	middle := (a+b)*0.5
	left_middle := (a+middle)*0.5
	right_middle := (middle+b)*0.5
	flm := sample(function_id, left_middle)
	frm := sample(function_id, right_middle)
	left := simpson(a, middle, fa, flm, fm)
	right := simpson(middle, b, fm, frm, fb)
	delta := left+right-whole
	if depth == 0 || math.abs_f64(delta) <= 15.0*tolerance {
		return left+right+delta/15.0
	}
	return refine(function_id, a, middle, fa, flm, fm, left, tolerance*0.5, depth-1) +
		refine(function_id, middle, b, fm, frm, fb, right, tolerance*0.5, depth-1)
}

exact_integer :: proc(x: f64, lo, hi: i64) -> bool {
	if math.is_nan(x) || math.is_inf(x) || x < f64(lo) || x > f64(hi) do return false
	return f64(i64(x)) == x
}

@(export)
adaptive_simpson_quadrature :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length != 5 || input_length > MAX_INPUT_LENGTH do return -1
	if !exact_integer(input[0], 0, 2) || !exact_integer(input[1], -2_000_000, 2_000_000) ||
		!exact_integer(input[2], -2_000_000, 2_000_000) ||
		!exact_integer(input[3], 7, 8) || !exact_integer(input[4], 8, 12) do return -1
	function_id := i64(input[0])
	a_micro := i64(input[1])
	b_micro := i64(input[2])
	exponent := i64(input[3])
	depth := i64(input[4])
	if a_micro > b_micro do return -1
	if output == nil || output_capacity < 1 do return -2
	a := f64(a_micro)/1_000_000.0
	b := f64(b_micro)/1_000_000.0
	result := f64(0.0)
	if a != b {
		middle := (a+b)*0.5
		tolerance := f64(1.0)
		for _ in 0..<exponent { tolerance *= 0.1 }
		fa := sample(function_id, a)
		fm := sample(function_id, middle)
		fb := sample(function_id, b)
		result = refine(function_id, a, b, fa, fm, fb, simpson(a,b,fa,fm,fb), tolerance, depth)
	}
	if math.is_nan(result) || math.is_inf(result) do return -1
	output[0] = result
	return 1
}
