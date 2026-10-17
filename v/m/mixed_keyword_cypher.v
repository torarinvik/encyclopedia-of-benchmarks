module mixed_keyword_cypher

const max_keyword_length = 64
const max_plaintext_length = 512
const max_input_length = 578

@[export: 'mixed_keyword_cypher']
pub fn mixed_keyword_cypher(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_input_length) { return -1 }
		raw_keyword_length := input[0]
		if raw_keyword_length < 1 || raw_keyword_length > max_keyword_length { return -1 }
		keyword_length := int(raw_keyword_length)
		plaintext_length_index := 1 + keyword_length
		if plaintext_length_index >= int(length) { return -1 }

		raw_plaintext_length := input[plaintext_length_index]
		if raw_plaintext_length < 0 || raw_plaintext_length > max_plaintext_length { return -1 }
		plaintext_length := int(raw_plaintext_length)
		if int(length) != plaintext_length_index + 1 + plaintext_length { return -1 }

		mut unique_letters := [26]u8{init: 0}
		mut seen := [26]bool{init: false}
		mut unique_count := 0
		for index := 0; index < keyword_length; index++ {
			raw := input[1 + index]
			if raw < 0 || raw > 127 { return -1 }
			mut letter := int(raw)
			if letter >= 'a' && letter <= 'z' { letter -= 'a' - 'A' }
			if letter >= 'A' && letter <= 'Z' {
				alphabet_index := letter - 'A'
				if !seen[alphabet_index] {
					seen[alphabet_index] = true
					unique_letters[unique_count] = u8(letter)
					unique_count++
				}
			}
		}
		if unique_count == 0 { return -1 }

		for index := 0; index < plaintext_length; index++ {
			raw := input[plaintext_length_index + 1 + index]
			if raw < 0 || raw > 127 { return -1 }
		}

		mut shifted := [26]u8{init: 0}
		for index := 0; index < unique_count; index++ { shifted[index] = unique_letters[index] }
		mut shifted_count := unique_count
		for index := 0; index < 26; index++ {
			if !seen[index] {
				shifted[shifted_count] = u8('A' + index)
				shifted_count++
			}
		}

		mut mapping := [26]u8{init: 0}
		mut alphabet_index := 0
		for column := 0; column < unique_count; column++ {
			mut row_start := 0
			for row_start < 26 {
				shifted_index := row_start + column
				if shifted_index >= 26 { break }
				mapping[alphabet_index] = shifted[shifted_index]
				alphabet_index++
				row_start += unique_count
			}
		}

		mut buffer := [max_plaintext_length]u8{init: 0}
		for index := 0; index < plaintext_length; index++ {
			mut letter := int(input[plaintext_length_index + 1 + index])
			if letter >= 'a' && letter <= 'z' { letter -= 'a' - 'A' }
			if letter >= 'A' && letter <= 'Z' {
				buffer[index] = mapping[letter - 'A']
			} else {
				buffer[index] = u8(letter)
			}
		}

		if output == nil || capacity < usize(plaintext_length) { return -2 }
		for index := 0; index < plaintext_length; index++ { output[index] = buffer[index] }
		return i64(plaintext_length)
	}
}
