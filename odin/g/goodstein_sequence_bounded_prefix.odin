package goodstein_sequence_bounded_prefix

import "core:c"

MAX_INPUT_WORDS :: 3
MAX_TRANSITIONS :: i64(16)

small_power :: proc(base, exponent: i64) -> i64 {
	result := i64(1)
	for index := i64(0); index < exponent; index += 1 {
		result *= base
	}
	return result
}

rebase_hereditary :: proc(value, base, raised_base: i64) -> i64 {
	if value == 0 do return 0
	result := i64(0)
	place := i64(1)
	exponent := i64(0)
	for place <= value {
		digit := (value / place) % base
		if digit != 0 {
			raised_exponent := rebase_hereditary(exponent, base, raised_base)
			result += digit * small_power(raised_base, raised_exponent)
		}
		place *= base
		exponent += 1
	}
	return result
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
goodstein_sequence_bounded_prefix :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_WORDS || length != 2 do return -1
	start := input[0]
	transitions := input[1]
	if start < 0 || start > 4 || transitions < 0 || transitions > MAX_TRANSITIONS do return -1

	terms: [17]i64 = {}
	count := 1
	terms[0] = start
	current := start
	base := i64(2)
	for step := i64(0); step < transitions && current != 0; step += 1 {
		current = rebase_hereditary(current, base, base + 1) - 1
		base += 1
		terms[count] = current
		count += 1
	}

	output_bytes := (count + 1) * 8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	store_i64_le(output, 0, i64(count))
	for index := 0; index < count; index += 1 {
		store_i64_le(output, (index + 1) * 8, terms[index])
	}
	return i64(output_bytes)
}
