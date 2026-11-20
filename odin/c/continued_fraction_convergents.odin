package continued_fraction_convergents

import "core:c"

MAX_INPUT_LENGTH :: 18

store_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
	bits := transmute(u64)value
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
continued_fraction_convergents :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	count_value := input[0]
	if count_value < 1 || count_value > 16 || input[1] < -1000 || input[1] > 1000 do return -1
	count := int(count_value)
	if int(length) != count + 1 do return -1
	for index := 2; index < int(length); index += 1 {
		if input[index] < 1 || input[index] > 8 do return -1
	}
	required := c.size_t(16 * count)
	if output == nil || capacity < required do return -2

	p_two_back, p_one_back := i64(0), i64(1)
	q_two_back, q_one_back := i64(1), i64(0)
	for index := 0; index < count; index += 1 {
		p := input[index+1]*p_one_back + p_two_back
		q := input[index+1]*q_one_back + q_two_back
		store_i64_le(output, c.size_t(16*index), p)
		store_i64_le(output, c.size_t(16*index+8), q)
		p_two_back, p_one_back = p_one_back, p
		q_two_back, q_one_back = q_one_back, q
	}
	return i64(required)
}
