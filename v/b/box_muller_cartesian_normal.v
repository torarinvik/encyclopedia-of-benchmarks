module box_muller_cartesian_normal

import math

const max_pairs = 64
const draw_scale = 4_294_967_296.0
const tau = 6.283185307179586476925286766559

fn is_bounded_integer(value f64, minimum f64, maximum f64) bool {
	return value.is_finite() && math.trunc(value) == value && value >= minimum && value <= maximum
}

@[export: 'box_muller_cartesian_normal']
pub fn box_muller_cartesian_normal(input &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(1 + 2 * max_pairs) { return -1 }
		if !is_bounded_integer(input[0], 1.0, f64(max_pairs)) { return -1 }
		pair_count := int(input[0])
		if length != usize(1 + 2 * pair_count) { return -1 }
		for index in 0 .. 2 * pair_count {
			if !is_bounded_integer(input[1 + index], 0.0, 4294967295.0) { return -1 }
		}

		result_count := 2 * pair_count
		if output == nil || capacity < usize(result_count) { return -2 }
		for pair in 0 .. pair_count {
			radial := (input[1 + 2 * pair] + 1.0) / draw_scale
			angular := input[2 + 2 * pair] / draw_scale
			radius := math.sqrt(-2.0 * math.log(radial))
			angle := tau * angular
			output[2 * pair] = radius * math.cos(angle)
			output[2 * pair + 1] = radius * math.sin(angle)
		}
		return i64(result_count)
	}
}
