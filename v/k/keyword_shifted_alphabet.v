module keyword_shifted_alphabet

const max_keyword_length = 26
const max_message_length = 512
const max_input_length = 3 + max_keyword_length + max_message_length + 1

@[export: 'keyword_shifted_alphabet']
pub fn keyword_shifted_alphabet(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if isnil(input) || length < 3 || length > usize(max_input_length) { return -1 }
	operation := unsafe { input }
	keyword_length_value := unsafe { input[1] }
	message_length_value := unsafe { input[2] }
	if (operation != 0 && operation != 1) || keyword_length_value < 1 || keyword_length_value > max_keyword_length ||
		message_length_value < 1 || message_length_value > max_message_length { return -1 }
	keyword_length := int(keyword_length_value)
	message_length := int(message_length_value)
	if length != usize(3 + keyword_length + message_length) { return -1 }

	mut keyword := []u8{len: max_keyword_length}
	mut seen := []bool{len: 26}
	for i in 0 .. keyword_length {
		value := unsafe { input[3 + i] }
		if !((value >= 65 && value <= 90) || (value >= 97 && value <= 122)) { return -1 }
		lower := if value >= 65 && value <= 90 { u8(value + 32) } else { u8(value) }
		index := int(lower - `a`)
		if seen[index] { return -1 }
		seen[index] = true
		keyword[i] = lower
	}
	mut message := []u8{len: max_message_length}
	for i in 0 .. message_length {
		value := unsafe { input[3 + keyword_length + i] }
		if value < 0 || value > 127 { return -1 }
		message[i] = u8(value)
	}

	mut cipher_alphabet := []u8{len: 26}
	mut encode := []u8{len: 26}
	mut decode := []u8{len: 26}
	mut cipher_length := 0
	for i in 0 .. keyword_length { cipher_alphabet[cipher_length] = keyword[i]; cipher_length++ }
	for i in 0 .. 26 {
		letter := u8(`a` + i)
		if !seen[i] { cipher_alphabet[cipher_length] = letter; cipher_length++ }
	}
	for i in 0 .. 26 {
		encode[i] = cipher_alphabet[i]
		decode[int(cipher_alphabet[i] - `a`)] = u8(`a` + i)
	}

	if output_capacity < usize(message_length) || isnil(output) { return -2 }
	for i in 0 .. message_length {
		value := message[i]
		uppercase := value >= `A` && value <= `Z`
		mut index := -1
		if uppercase { index = int(value - `A`) }
		else if value >= `a` && value <= `z` { index = int(value - `a`) }
		if index < 0 { unsafe { output[i] = value }; continue }
		translated := if operation == 0 { encode[index] } else { decode[index] }
		unsafe { output[i] = if uppercase { translated - 32 } else { translated } }
	}
	return i64(message_length)
}
