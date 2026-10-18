fn exact_integer(value f64, minimum i64, maximum i64) bool {
	if !value.is_finite() || value < f64(minimum) || value > f64(maximum) { return false }
	return f64(i64(value)) == value
}

fn allowed_coordinate(value f64) bool {
	return value == 0 || value == 0.25 || value == 0.5 || value == 0.75
}

@[export: 'montecarlopi']
pub fn montecarlopi(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > 130 { return -1 }
		if !exact_integer(input[0], 1, 64) { return -1 }
		point_count := int(input[0])
		if input_length != usize(1 + 2 * point_count) { return -1 }
		mut inside := 0
		for point in 0 .. point_count {
			x, y := input[1 + 2 * point], input[2 + 2 * point]
			if !allowed_coordinate(x) || !allowed_coordinate(y) { return -1 }
			if x * x + y * y <= 1.0 { inside++ }
		}
		estimate := f64(inside) / f64(point_count) * 4.0
		if !estimate.is_finite() { return -1 }
		if output == nil || capacity < 1 { return -2 }
		output[0] = estimate
		return 1
	}
}
