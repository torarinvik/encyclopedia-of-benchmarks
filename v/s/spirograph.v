import math

fn exact_integer(value f64, minimum i64, maximum i64) bool {
	if !value.is_finite() || value < f64(minimum) || value > f64(maximum) { return false }
	return f64(i64(value)) == value
}

@[export: 'spirograph']
pub fn spirograph(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > 5 { return -1 }
		if input_length != 4 || !exact_integer(input[0], 1, 32) { return -1 }
		points := int(input[0])
		marker_ratio, inner_ratio, rotations := input[1], input[2], input[3]
		if !marker_ratio.is_finite() || marker_ratio < 0 || marker_ratio > 1 { return -1 }
		if !inner_ratio.is_finite() || inner_ratio < 0.25 || inner_ratio > 0.75 { return -1 }
		if !rotations.is_finite() || rotations < 0 || rotations > 10 { return -1 }

		delta := rotations * 2.0 * 3.14159265358979323846 / f64(points)
		k1 := 1.0 - inner_ratio
		mut staged := [64]f64{}
		for index in 0 .. points {
			t := f64(index) * delta
			inner_angle := k1 * t / inner_ratio
			x := k1 * math.cos(t) + marker_ratio * inner_ratio * math.cos(inner_angle)
			y := k1 * math.sin(t) - marker_ratio * inner_ratio * math.sin(inner_angle)
			if !x.is_finite() || !y.is_finite() { return -1 }
			staged[2 * index] = x
			staged[2 * index + 1] = y
		}

		output_length := 2 * points
		if output == nil || capacity < usize(output_length) { return -2 }
		for index in 0 .. output_length { output[index] = staged[index] }
		return i64(output_length)
	}
}
