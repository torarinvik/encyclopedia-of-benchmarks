package addition_of_big_integers

import "core:c"

addition_of_big_integers :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 68 do return -1
	raw_a, raw_b := input[0], input[1]
	if raw_a < 1 || raw_a > 33 || raw_b < 1 || raw_b > 33 do return -1
	len_a, len_b := int(raw_a), int(raw_b)
	if length != c.size_t(2 + len_a + len_b) do return -1

	starts: [2]int = {2, 2 + len_a}
	counts: [2]int
	negative: [2]bool
	text_lengths: [2]int = {len_a, len_b}
	for operand := 0; operand < 2; operand += 1 {
		if text_lengths[operand] < 1 || text_lengths[operand] > 33 do return -1
		negative[operand] = input[starts[operand]] == 45
		sign_length := 0
		if negative[operand] { starts[operand] += 1; sign_length = 1 }
		counts[operand] = text_lengths[operand] - sign_length
		if counts[operand] < 1 || counts[operand] > 32 do return -1
		for index := 0; index < counts[operand]; index += 1 {
			byte := input[starts[operand] + index]
			if byte < 48 || byte > 57 || (index == 0 && counts[operand] > 1 && byte == 48) do return -1
		}
		if negative[operand] && counts[operand] == 1 && input[starts[operand]] == 48 do return -1
	}

	var reversed: [33]u8
	digits := 0
	negative_result := false
	if negative[0] == negative[1] {
		negative_result = negative[0]
		width := counts[0]
		if counts[1] > width do width = counts[1]
		carry := 0
		for offset := 0; offset < width; offset += 1 {
			da := 0
			db := 0
			if offset < counts[0] do da = int(input[starts[0] + counts[0] - 1 - offset] - 48)
			if offset < counts[1] do db = int(input[starts[1] + counts[1] - 1 - offset] - 48)
			total := da + db + carry
			reversed[digits] = u8(total % 10)
			digits += 1
			carry = total / 10
		}
		if carry != 0 {
			reversed[digits] = u8(carry)
			digits += 1
		}
	} else {
		order := 0
		if counts[0] > counts[1] { order = 1 } else if counts[0] < counts[1] { order = -1 } else {
			for index := 0; index < counts[0] && order == 0; index += 1 {
				da, db := input[starts[0] + index], input[starts[1] + index]
				if da > db { order = 1 } else if da < db { order = -1 }
			}
		}
		if order == 0 {
			reversed[0] = 0
			digits = 1
		} else {
			big, small := 0, 1
			if order < 0 { big, small = 1, 0 }
			negative_result = negative[big]
			borrow := 0
			for offset := 0; offset < counts[big]; offset += 1 {
				da := int(input[starts[big] + counts[big] - 1 - offset] - 48)
				db := 0
				if offset < counts[small] do db = int(input[starts[small] + counts[small] - 1 - offset] - 48)
				digit := da - db - borrow
				borrow = 0
				if digit < 0 { borrow = 1; digit += 10 }
				reversed[digits] = u8(digit)
				digits += 1
			}
			for digits > 1 && reversed[digits - 1] == 0 { digits -= 1 }
		}
	}

	sign_length := 0
	if negative_result do sign_length = 1
	output_length := c.size_t(digits + sign_length)
	if output == nil || capacity < output_length do return -2
	cursor := 0
	if negative_result { output[cursor] = 45; cursor += 1 }
	for index := 0; index < digits; index += 1 {
		output[cursor] = 48 + reversed[digits - 1 - index]
		cursor += 1
	}
	return i64(output_length)
}
