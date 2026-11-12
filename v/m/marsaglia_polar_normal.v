module marsaglia_polar_normal

import math

const max_draws = 128
const max_attempts = 64
const draw_scale = 2147483648.0

fn is_bounded_integer(value f64, minimum f64, maximum f64) bool {
	return value.is_finite() && math.trunc(value) == value && value >= minimum && value <= maximum
}

@[export: 'marsaglia_polar_normal']
pub fn marsaglia_polar_normal(input &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > usize(2 + max_draws) { return -1 }
		if !is_bounded_integer(input[0], 2.0, f64(max_draws)) ||
			!is_bounded_integer(input[1], 1.0, f64(max_attempts)) { return -1 }
		draw_count := int(input[0])
		attempt_cap := int(input[1])
		if draw_count % 2 != 0 || length != usize(2 + draw_count) || draw_count < 2 * attempt_cap { return -1 }
		for index in 0 .. draw_count {
			if !is_bounded_integer(input[2 + index], 0.0, 4294967295.0) { return -1 }
		}

		mut first := f64(0.0)
		mut second := f64(0.0)
		mut accepted := false
		for attempt in 0 .. attempt_cap {
			u1 := input[2 + 2 * attempt] / draw_scale - 1.0
			u2 := input[3 + 2 * attempt] / draw_scale - 1.0
			radius_squared := u1 * u1 + u2 * u2
			if radius_squared <= 0.0 || radius_squared >= 1.0 { continue }
			scale := math.sqrt(-2.0 * math.log(radius_squared) / radius_squared)
			first, second = u1 * scale, u2 * scale
			accepted = true
			break
		}
		if !accepted { return -1 }
		if output == nil || capacity < 2 { return -2 }
		output[0], output[1] = first, second
		return 2
	}
}
