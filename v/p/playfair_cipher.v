module playfair_cipher

const min_parseable_input_length = 3
const max_parseable_input_length = 157
const max_key_length = 25
const max_text_length = 128
const fnv_offset_basis = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)
const low63_mask = u64(0x7fffffffffffffff)
const alphabet = 'ABCDEFGHIKLMNOPQRSTUVWXYZ'

@[export: 'playfair_cipher']
pub fn playfair_cipher(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < usize(min_parseable_input_length) || length > usize(max_parseable_input_length) { return -1 }
		operation, key_length_value := input[0], input[1]
		if operation < 0 || operation > 1 || key_length_value < 0 || key_length_value > max_key_length { return -1 }
		key_length := int(key_length_value)
		text_length_index := 2 + key_length
		if length <= usize(text_length_index) { return -1 }
		text_length_value := input[text_length_index]
		if text_length_value < 0 || text_length_value > max_text_length || text_length_value % 2 != 0 { return -1 }
		text_length := int(text_length_value)
		text_start := text_length_index + 1
		if length != usize(text_start + text_length) { return -1 }

		mut seen := [26]bool{}
		mut square := [25]u8{}
		mut square_length := 0
		for index in 0 .. key_length {
			value := input[2 + index]
			if value < 65 || value > 90 || value == 74 { return -1 }
			letter := u8(value)
			slot := int(letter - u8(`A`))
			if !seen[slot] {
				seen[slot] = true
				square[square_length] = letter
				square_length++
			}
		}
		for character in alphabet.bytes() {
			letter := u8(character)
			slot := int(letter - u8(`A`))
			if !seen[slot] {
				seen[slot] = true
				square[square_length] = letter
				square_length++
			}
		}

		mut positions := [26]u8{}
		for index, letter in square {
			positions[int(letter - u8(`A`))] = u8(index)
		}

		mut previous := u8(0)
		for index in 0 .. text_length {
			value := input[text_start + index]
			if value < 65 || value > 90 || value == 74 { return -1 }
			letter := u8(value)
			if operation == 0 && index > 0 && letter == previous { return -1 }
			previous = letter
		}

		mut hash := fnv_offset_basis
		shift := if operation == 0 { 1 } else { -1 }
		mut index := 0
		for index < text_length {
			first := u8(input[text_start + index])
			second := u8(input[text_start + index + 1])
			position1 := int(positions[int(first - u8(`A`))])
			position2 := int(positions[int(second - u8(`A`))])
			row1, column1 := position1 / 5, position1 % 5
			row2, column2 := position2 / 5, position2 % 5
			mut result1, mut result2 := u8(0), u8(0)
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
			hash = (hash ^ u64(result1)) * fnv_prime
			hash = (hash ^ u64(result2)) * fnv_prime
			index += 2
		}
		return i64(hash & low63_mask)
	}
}
