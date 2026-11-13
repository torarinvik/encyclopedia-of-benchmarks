import math

fn ridders_exact_integer(value f64, low i64, high i64) bool {
	return value.is_finite() && value >= f64(low) && value <= f64(high) && f64(i64(value)) == value
}

fn ridders_polynomial(id i64, x f64) f64 {
	if id == 0 { return x*x-2.0 }
	if id == 1 { return x*x*x-2.0 }
	if id == 2 { return x*x*x+x-1.0 }
	return x
}

fn ridders_opposite(a f64, b f64) bool { return (a < 0.0) != (b < 0.0) }

@[export: 'ridders_root_finding']
pub fn ridders_root_finding(input &f64, input_length usize,
	mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length != 5 || input_length > 6 { return -1 }
		if !ridders_exact_integer(input[0], 0, 3) || !ridders_exact_integer(input[1], -3000, 3000) ||
			!ridders_exact_integer(input[2], -3000, 3000) || !ridders_exact_integer(input[3], 1, 1000) ||
			!ridders_exact_integer(input[4], 24, 32) { return -1 }
		id := i64(input[0])
		left_milli := i64(input[1])
		right_milli := i64(input[2])
		tolerance_micro := i64(input[3])
		iterations := i64(input[4])
		if left_milli >= right_milli { return -1 }
		mut left := f64(left_milli)/1000.0
		mut right := f64(right_milli)/1000.0
		mut f_left := ridders_polynomial(id, left)
		mut f_right := ridders_polynomial(id, right)
		if f_left != 0.0 && f_right != 0.0 && !ridders_opposite(f_left, f_right) { return -1 }
		if output == nil || output_capacity < 1 { return -2 }
		if f_left == 0.0 { output[0] = left; return 1 }
		if f_right == 0.0 { output[0] = right; return 1 }
		tolerance := f64(tolerance_micro)/1000000.0
		for _ in 0 .. iterations {
			if right-left <= tolerance { output[0] = (left+right)*0.5; return 1 }
			middle := (left+right)*0.5
			f_middle := ridders_polynomial(id, middle)
			if f_middle == 0.0 { output[0] = middle; return 1 }
			radicand := f_middle*f_middle-f_left*f_right
			if !radicand.is_finite() || radicand <= 0.0 { return -3 }
			denominator := math.sqrt(radicand)
			if !denominator.is_finite() || denominator == 0.0 { return -3 }
			direction := f64(1.0)
			if f_left < f_right { direction = -1.0 }
			candidate := middle+(middle-left)*direction*f_middle/denominator
			if !candidate.is_finite() || candidate <= left || candidate >= right { return -3 }
			f_candidate := ridders_polynomial(id, candidate)
			if f_candidate == 0.0 { output[0] = candidate; return 1 }
			if ridders_opposite(f_left, f_candidate) { right = candidate; f_right = f_candidate }
			else { left = candidate; f_left = f_candidate }
			if right-left <= tolerance { output[0] = (left+right)*0.5; return 1 }
		}
		return -3
	}
}
