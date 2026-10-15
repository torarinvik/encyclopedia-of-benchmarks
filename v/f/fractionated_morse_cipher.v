module fractionated_morse_cipher

const morse_code = [26]u8{1,8,10,4,0,2,6,0,0,7,5,4,3,2,7,6,13,2,0,1,1,1,3,9,11,12}
const morse_length = [26]int{2,4,4,3,1,4,3,4,2,4,3,4,2,2,3,4,4,3,3,1,3,4,3,4,4,4}
const morse_symbols = [3]u8{46,45,120}

fn make_keyed_alphabet(input &i64, key_start int, key_length int) [26]u8 {
	mut keyed := [26]u8{}
	mut seen := [26]bool{}
	mut count := 0
	for index in 0 .. key_length {
		mut value := unsafe { input[key_start + index] }
		if value >= 97 && value <= 122 { value -= 32 }
		letter := int(value - 65)
		if !seen[letter] { seen[letter] = true; keyed[count] = u8(value); count++ }
	}
	for letter in 0 .. 26 {
		if !seen[letter] { keyed[count] = u8(65 + letter); count++ }
	}
	return keyed
}

fn morse_letter(morse &u8, start int, length int) int {
	if length < 1 || length > 4 { return -1 }
	mut code := 0
	for offset in 0 .. length {
		symbol := unsafe { morse[start + offset] }
		bit := if symbol == 45 { 1 } else { 0 }
		code = code * 2 + bit
	}
	for letter in 0 .. 26 {
		if morse_length[letter] == length && int(morse_code[letter]) == code { return letter }
	}
	return -1
}

@[export: 'fractionated_morse_cipher']
pub fn fractionated_morse_cipher(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 3 || length > 323 || unsafe { input == nil } { return -1 }
	unsafe {
		mode := input[0]
		text_value := input[1]
		key_value := input[2]
		if (mode != 0 && mode != 1) || text_value < 0 || text_value > 256 || key_value < 0 || key_value > 64 { return -1 }
		text_length := int(text_value)
		key_length := int(key_value)
		if int(length) != 3 + text_length + key_length { return -1 }
		key_start := 3 + text_length
		for index in 0 .. key_length {
			value := input[key_start + index]
			if !((value >= 65 && value <= 90) || (value >= 97 && value <= 122)) { return -1 }
		}
		for index in 0 .. text_length {
			value := input[3 + index]
			if mode == 0 {
				if value != 32 && !((value >= 65 && value <= 90) || (value >= 97 && value <= 122)) { return -1 }
			} else if value < 65 || value > 90 { return -1 }
		}
		keyed := make_keyed_alphabet(input, key_start, key_length)
		mut result := [800]u8{}
		mut result_length := 0
		if mode == 0 {
			mut morse := [1300]u8{}
			mut morse_size := 0
			for index in 0 .. text_length {
				if index != 0 { morse[morse_size] = 120; morse_size++ }
				mut value := input[3 + index]
				if value == 32 { continue }
				if value >= 97 && value <= 122 { value -= 32 }
				letter := int(value - 65)
				for bit in 0 .. morse_length[letter] {
					mask := 1 << (morse_length[letter] - bit - 1)
					morse[morse_size] = if (int(morse_code[letter]) & mask) != 0 { 45 } else { 46 }
					morse_size++
				}
			}
			padding := 3 - morse_size % 3
			for _ in 0 .. padding { morse[morse_size] = 120; morse_size++ }
			for start := 0; start < morse_size; start += 3 {
				mut trigram := 0
				for offset in 0 .. 3 {
					digit := if morse[start + offset] == 46 { 0 } else if morse[start + offset] == 45 { 1 } else { 2 }
					trigram = trigram * 3 + digit
				}
				if trigram < 26 { result[result_length] = keyed[trigram]; result_length++ }
			}
		} else {
			mut morse := [1300]u8{}
			mut morse_size := 0
			for index in 0 .. text_length {
				mut trigram := 0
				for trigram < 26 && keyed[trigram] != u8(input[3 + index]) { trigram++ }
				if trigram == 26 { return -1 }
				morse[morse_size] = morse_symbols[trigram / 9]
				morse[morse_size + 1] = morse_symbols[(trigram / 3) % 3]
				morse[morse_size + 2] = morse_symbols[trigram % 3]
				morse_size += 3
			}
			mut segment_start := 0
			for index in 0 .. (morse_size + 1) {
				if index != morse_size && morse[index] != 120 { continue }
				segment_length := index - segment_start
				if segment_length == 0 { result[result_length] = 32; result_length++ }
				else {
					letter := morse_letter(&morse[0], segment_start, segment_length)
					if letter < 0 { return -1 }
					result[result_length] = u8(65 + letter); result_length++
				}
				segment_start = index + 1
			}
			mut first := 0
			for first < result_length && result[first] == 32 { first++ }
			for result_length > first && result[result_length - 1] == 32 { result_length-- }
			if first > 0 {
				for index in first .. result_length { result[index - first] = result[index] }
				result_length -= first
			}
		}
		if output_capacity < usize(result_length) || (result_length > 0 && output == nil) { return -2 }
		for index in 0 .. result_length { output[index] = result[index] }
		return i64(result_length)
	}
}
