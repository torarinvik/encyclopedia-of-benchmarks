package berlekamp_massey

import "core:c"

MODULUS :: i64(998244353)
MAX_ORDER :: 8
MAX_TERMS :: 2 * MAX_ORDER
MAX_INPUT_VALUES :: 1 + MAX_TERMS + 1

normalize :: proc(value: i64) -> i64 {
	result := value % MODULUS
	if result < 0 do result += MODULUS
	return result
}

multiply :: proc(left, right: i64) -> i64 {
	return (left * right) % MODULUS
}

power :: proc(base_value, exponent_value: i64) -> i64 {
	base := base_value
	exponent := exponent_value
	result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = multiply(result, base)
		base = multiply(base, base)
		exponent >>= 1
	}
	return result
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

infer_recurrence :: proc(sequence: [^]i64, term_count: int,
	coefficients: [^]i64) -> int {
	current: [MAX_TERMS + 1]i64
	previous: [MAX_TERMS + 1]i64
	old: [MAX_TERMS + 1]i64
	current_length := 0
	previous_length := 0
	last_index := -1
	last_discrepancy := i64(0)

	for index := 0; index < term_count; index += 1 {
		predicted := i64(0)
		for lag := 0; lag < current_length && lag < index; lag += 1 {
			predicted = normalize(predicted + multiply(sequence[index - lag - 1], current[lag]))
		}
		discrepancy := normalize(sequence[index] - predicted)
		if discrepancy == 0 do continue

		if last_index < 0 {
			last_index = index
			last_discrepancy = discrepancy
			current_length = index + 1
			for lag := 0; lag < current_length; lag += 1 do current[lag] = 0
			continue
		}

		for lag := 0; lag < current_length; lag += 1 do old[lag] = current[lag]
		old_length := current_length
		shift := index - last_index
		scale := multiply(discrepancy, power(last_discrepancy, MODULUS - 2))
		needed_length := previous_length + shift
		if current_length < needed_length {
			for lag := current_length; lag < needed_length; lag += 1 do current[lag] = 0
			current_length = needed_length
		}
		current[shift - 1] = normalize(current[shift - 1] + scale)
		for lag := 0; lag < previous_length; lag += 1 {
			current[shift + lag] = normalize(current[shift + lag] - multiply(scale, previous[lag]))
		}
		if old_length - index < previous_length - last_index {
			for lag := 0; lag < old_length; lag += 1 do previous[lag] = old[lag]
			previous_length = old_length
			last_index = index
			last_discrepancy = discrepancy
		}
	}

	for lag := 0; lag < current_length; lag += 1 do coefficients[lag] = current[lag]
	return current_length
}

@(export)
berlekamp_massey :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
	bound_value := input[0]
	if bound_value < 1 || bound_value > i64(MAX_ORDER) do return -1
	bound := int(bound_value)
	term_count := 2 * bound
	if length != c.size_t(1 + term_count) do return -1

	sequence: [MAX_TERMS]i64
	for index := 0; index < term_count; index += 1 {
		value := input[1 + index]
		if value < 0 || value >= MODULUS do return -1
		sequence[index] = value
	}
	coefficients: [MAX_TERMS + 1]i64
	order := infer_recurrence(&sequence[0], term_count, &coefficients[0])
	if order > bound do return -1

	output_bytes := c.size_t(8 * (order + 1))
	if output == nil || capacity < output_bytes do return -2
	store_i64_le(output, 0, i64(order))
	for lag := 0; lag < order; lag += 1 {
		store_i64_le(output, 8 * (lag + 1), coefficients[lag])
	}
	return i64(output_bytes)
}
