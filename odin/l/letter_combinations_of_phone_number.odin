package letter_combinations_of_phone_number

import "core:c"

letter_count :: proc "contextless" (digit: i64) -> c.size_t {
	if digit == 7 || digit == 9 do return 4
	return 3
}

letter_base :: proc "contextless" (digit: i64) -> u8 {
	switch digit {
	case 2: return u8('a')
	case 3: return u8('d')
	case 4: return u8('g')
	case 5: return u8('j')
	case 6: return u8('m')
	case 7: return u8('p')
	case 8: return u8('t')
	case: return u8('w')
	}
}

expand :: proc "contextless" (digits: [^]i64, length, index: c.size_t, output: [^]u8,
		output_offset, combination_count: c.size_t) {
	if index == length do return
	alternatives := letter_count(digits[index])
	block_count := combination_count / alternatives
	base := letter_base(digits[index])
	for letter: c.size_t = 0; letter < alternatives; letter += 1 {
		branch_offset := output_offset + letter * block_count * length
		for row: c.size_t = 0; row < block_count; row += 1 {
			output[branch_offset + row * length + index] = base + u8(letter)
		}
		expand(digits, length, index + 1, output, branch_offset, block_count)
	}
}

// Recursively enumerate 2–9 keypad letters into fixed-width concatenated slots.
@(export)
letter_combinations_of_phone_number :: proc "c" (digits: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length == 0 do return 0
	if length > 6 || digits == nil do return -1
	count := c.size_t(1)
	for index: c.size_t = 0; index < length; index += 1 {
		digit := digits[index]
		if digit < 2 || digit > 9 do return -1
		count *= letter_count(digit)
	}
	required := count * length
	if output_capacity < required || output == nil do return -2
	expand(digits, length, 0, output, 0, count)
	return i64(count)
}
