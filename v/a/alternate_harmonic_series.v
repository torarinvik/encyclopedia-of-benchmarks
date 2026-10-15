module alternate_harmonic_series

const max_count = 1000

// Check alternating signs and constant differences between reciprocal magnitudes.
@[export: 'alternate_harmonic_series']
pub fn alternate_harmonic_series(input &i64, length usize) i64 {
	if length < 1 { return -1 }
	count := unsafe { input[0] }
	if count < 1 || count > max_count || length != usize(1 + 2 * count) { return -1 }
	for index in 0 .. int(count) {
		numerator := unsafe { input[1 + 2 * index] }
		denominator := unsafe { input[2 + 2 * index] }
		if numerator < -1000 || numerator > 1000 || numerator == 0 || denominator < 1 || denominator > 1000 { return -1 }
	}
	mut previous_sign := i64(0)
	mut previous_reciprocal_numerator := i64(0)
	mut previous_reciprocal_denominator := i64(1)
	mut step_numerator := i64(0)
	mut step_denominator := i64(1)
	for index in 0 .. int(count) {
		numerator := unsafe { input[1 + 2 * index] }
		denominator := unsafe { input[2 + 2 * index] }
		if numerator < -1000 || numerator > 1000 || numerator == 0 || denominator < 1 || denominator > 1000 { return -1 }
		sign := i64(1)
		mut magnitude := numerator
		if numerator < 0 {
			sign = -1
			magnitude = -numerator
		}
		reciprocal_numerator := denominator
		reciprocal_denominator := magnitude
		if index > 0 {
			if index > 1 && sign == previous_sign { return 0 }
			current_delta_numerator := reciprocal_numerator * previous_reciprocal_denominator - previous_reciprocal_numerator * reciprocal_denominator
			current_delta_denominator := reciprocal_denominator * previous_reciprocal_denominator
			if index == 1 {
				step_numerator = current_delta_numerator
				step_denominator = current_delta_denominator
			} else if current_delta_numerator * step_denominator != step_numerator * current_delta_denominator {
				return 0
			}
		}
		previous_sign = sign
		previous_reciprocal_numerator = reciprocal_numerator
		previous_reciprocal_denominator = reciprocal_denominator
	}
	return 1
}
