module circular_mean_direction

import math

const pi_value = 3.14159265358979323846264338327950288
const tau_value = 6.28318530717958647692528676655900576
const cutoff_scale = 0.0000000037252902984619140625

fn cmd_wrap(angle f64) f64 {
	mut value := angle - math.floor((angle + pi_value) / tau_value) * tau_value
	if value >= pi_value { value -= tau_value }
	if value < -pi_value { value += tau_value }
	return value
}

@[export: 'circular_mean_direction']
pub fn circular_mean_direction(input &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 66 { return -1 }
		count_value := input[0]
		if !count_value.is_finite() || math.trunc(count_value) != count_value ||
			count_value < 1.0 || count_value > 64.0 { return -1 }
		count := int(count_value)
		if length != count + 1 { return -1 }

		mut sum_cos := f64(0.0)
		mut sum_sin := f64(0.0)
		mut correction_cos := f64(0.0)
		mut correction_sin := f64(0.0)
		for index in 0 .. count {
			raw := input[index + 1]
			if !raw.is_finite() || raw.abs() > 8.0 * pi_value { return -1 }
			angle := cmd_wrap(raw)
			adjusted_cos := math.cos(angle) - correction_cos
			next_cos := sum_cos + adjusted_cos
			correction_cos = (next_cos - sum_cos) - adjusted_cos
			sum_cos = next_cos
			adjusted_sin := math.sin(angle) - correction_sin
			next_sin := sum_sin + adjusted_sin
			correction_sin = (next_sin - sum_sin) - adjusted_sin
			sum_sin = next_sin
		}
		resultant := math.sqrt(sum_cos * sum_cos + sum_sin * sum_sin)
		if !resultant.is_finite() || resultant <= f64(count) * cutoff_scale { return -1 }
		if output == nil || capacity < 1 { return -2 }
		output[0] = cmd_wrap(math.atan2(sum_sin, sum_cos))
		return 1
	}
}
