package alternate_harmonic_series

import "core:c"

MAX_COUNT :: 1000

// Check alternating signs and constant differences between reciprocal magnitudes.
@(export)
alternate_harmonic_series :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	count := input[0]
	if count < 1 || count > MAX_COUNT || length != c.size_t(1+2*count) do return -1
	for index := i64(0); index < count; index += 1 {
		numerator := input[1+2*index]
		denominator := input[2+2*index]
		if numerator < -1000 || numerator > 1000 || numerator == 0 || denominator < 1 || denominator > 1000 do return -1
	}

	previous_sign := i64(0)
	previous_reciprocal_numerator := i64(0)
	previous_reciprocal_denominator := i64(1)
	step_numerator := i64(0)
	step_denominator := i64(1)
	for index := i64(0); index < count; index += 1 {
		numerator := input[1+2*index]
		denominator := input[2+2*index]
		if numerator < -1000 || numerator > 1000 || numerator == 0 || denominator < 1 || denominator > 1000 do return -1
		sign := i64(1)
		magnitude := numerator
		if numerator < 0 {
			sign = -1
			magnitude = -numerator
		}
		reciprocal_numerator := denominator
		reciprocal_denominator := magnitude
		if index > 0 {
            if index > 1 && sign == previous_sign do return 0
			// Compare reciprocal deltas exactly by cross multiplication.
			current_delta_numerator := reciprocal_numerator*previous_reciprocal_denominator - previous_reciprocal_numerator*reciprocal_denominator
			current_delta_denominator := reciprocal_denominator*previous_reciprocal_denominator
			if index == 1 {
				step_numerator = current_delta_numerator
				step_denominator = current_delta_denominator
			} else if current_delta_numerator*step_denominator != step_numerator*current_delta_denominator {
				return 0
			}
		}
		previous_sign = sign
		previous_reciprocal_numerator = reciprocal_numerator
		previous_reciprocal_denominator = reciprocal_denominator
	}
	return 1
}
