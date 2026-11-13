import math

fn adaptive_sample(function_id i64, x f64) f64 {
	if function_id == 0 { return x*x*x*x }
	if function_id == 1 { return math.sin(x) }
	return 1.0/(1.0+x*x)
}

fn adaptive_simpson(a f64, b f64, fa f64, fm f64, fb f64) f64 {
	return (b-a)*(fa+4.0*fm+fb)/6.0
}

fn adaptive_refine(function_id i64, a f64, b f64, fa f64, fm f64, fb f64,
	whole f64, tolerance f64, depth i64) f64 {
	middle := (a+b)*0.5
	left_middle := (a+middle)*0.5
	right_middle := (middle+b)*0.5
	flm := adaptive_sample(function_id, left_middle)
	frm := adaptive_sample(function_id, right_middle)
	left := adaptive_simpson(a, middle, fa, flm, fm)
	right := adaptive_simpson(middle, b, fm, frm, fb)
	delta := left+right-whole
	if depth == 0 || math.abs(delta) <= 15.0*tolerance {
		return left+right+delta/15.0
	}
	return adaptive_refine(function_id, a, middle, fa, flm, fm, left, tolerance*0.5, depth-1) +
		adaptive_refine(function_id, middle, b, fm, frm, fb, right, tolerance*0.5, depth-1)
}

fn adaptive_exact_integer(x f64, low i64, high i64) bool {
	return x.is_finite() && x >= f64(low) && x <= f64(high) && f64(i64(x)) == x
}

@[export: 'adaptive_simpson_quadrature']
pub fn adaptive_simpson_quadrature(input &f64, input_length usize,
	mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length != 5 || input_length > 6 { return -1 }
		if !adaptive_exact_integer(input[0], 0, 2) ||
			!adaptive_exact_integer(input[1], -2000000, 2000000) ||
			!adaptive_exact_integer(input[2], -2000000, 2000000) ||
			!adaptive_exact_integer(input[3], 7, 8) ||
			!adaptive_exact_integer(input[4], 8, 12) { return -1 }
		function_id := i64(input[0]); a_micro := i64(input[1]); b_micro := i64(input[2])
		exponent := i64(input[3]); depth := i64(input[4])
		if a_micro > b_micro { return -1 }
		if output == nil || output_capacity < 1 { return -2 }
		a := f64(a_micro)/1000000.0; b := f64(b_micro)/1000000.0
		mut result := f64(0.0)
		if a != b {
			middle := (a+b)*0.5
			mut tolerance := f64(1.0)
			for _ in 0 .. exponent { tolerance *= 0.1 }
			fa := adaptive_sample(function_id, a); fm := adaptive_sample(function_id, middle)
			fb := adaptive_sample(function_id, b)
			result = adaptive_refine(function_id, a, b, fa, fm, fb,
				adaptive_simpson(a,b,fa,fm,fb), tolerance, depth)
		}
		if !result.is_finite() { return -1 }
		output[0] = result
		return 1
	}
}
