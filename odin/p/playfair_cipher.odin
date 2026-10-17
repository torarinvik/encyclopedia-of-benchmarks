package playfair_cipher

import "core:c"

MIN_PARSEABLE_INPUT_LENGTH :: c.size_t(3)
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(157)
MAX_KEY_LENGTH :: 25
MAX_TEXT_LENGTH :: 128
FNV_OFFSET_BASIS :: u64(14_695_981_039_346_656_037)
FNV_PRIME :: u64(1_099_511_628_211)
LOW63_MASK :: u64(0x7fff_ffff_ffff_ffff)

@(export)
playfair_cipher :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < MIN_PARSEABLE_INPUT_LENGTH || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	operation, key_length_value := input[0], input[1]
	if operation < 0 || operation > 1 || key_length_value < 0 || key_length_value > MAX_KEY_LENGTH do return -1
	key_length := int(key_length_value)
	text_length_index := 2 + key_length
	if length <= c.size_t(text_length_index) do return -1
	text_length_value := input[text_length_index]
	if text_length_value < 0 || text_length_value > MAX_TEXT_LENGTH || text_length_value % 2 != 0 do return -1
	text_length := int(text_length_value)
	text_start := text_length_index + 1
	if length != c.size_t(text_start + text_length) do return -1

	var seen: [26]bool
	var square: [25]u8
	square_length := 0
	for index := 0; index < key_length; index += 1 {
		value := input[2 + index]
		if value < 65 || value > 90 || value == 74 do return -1
		letter := u8(value)
		slot := int(letter - u8('A'))
		if !seen[slot] {
			seen[slot] = true
			square[square_length] = letter
			square_length += 1
		}
	}
	for letter_value := 65; letter_value <= 90; letter_value += 1 {
		if letter_value == 74 do continue
		letter := u8(letter_value)
		slot := int(letter - u8('A'))
		if !seen[slot] {
			seen[slot] = true
			square[square_length] = letter
			square_length += 1
		}
	}

	var positions: [26]u8
	for index := 0; index < 25; index += 1 {
		positions[int(square[index] - u8('A'))] = u8(index)
	}

	previous := u8(0)
	for index := 0; index < text_length; index += 1 {
		value := input[text_start + index]
		if value < 65 || value > 90 || value == 74 do return -1
		letter := u8(value)
		if operation == 0 && index > 0 && letter == previous do return -1
		previous = letter
	}

	hash := FNV_OFFSET_BASIS
	shift := 1
	if operation == 1 { shift = -1 }
	for index := 0; index < text_length; index += 2 {
		first := u8(input[text_start + index])
		second := u8(input[text_start + index + 1])
		position1 := int(positions[int(first - u8('A'))])
		position2 := int(positions[int(second - u8('A'))])
		row1, column1 := position1 / 5, position1 % 5
		row2, column2 := position2 / 5, position2 % 5
		result1, result2 := u8(0), u8(0)
		if row1 == row2 {
			next1 := (column1 + shift + 5) % 5
			next2 := (column2 + shift + 5) % 5
			result1, result2 = square[row1 * 5 + next1], square[row2 * 5 + next2]
		} else if column1 == column2 {
			next1 := (row1 + shift + 5) % 5
			next2 := (row2 + shift + 5) % 5
			result1, result2 = square[next1 * 5 + column1], square[next2 * 5 + column2]
		} else {
			result1, result2 = square[row1 * 5 + column2], square[row2 * 5 + column1]
		}
		hash = (hash ^ u64(result1)) * FNV_PRIME
		hash = (hash ^ u64(result2)) * FNV_PRIME
	}
	return i64(hash & LOW63_MASK)
}
