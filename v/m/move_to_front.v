module main

const max_alphabet_length = 32
const max_text_length = 128

@[export: 'move_to_front']
pub fn move_to_front(values &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length < 3 || length > 164 { return -1 }
		mode := values[0]
		alphabet_length := values[1]
		text_length := values[2]
		if (mode != 0 && mode != 1) || alphabet_length < 0 || alphabet_length > max_alphabet_length ||
			text_length < 0 || text_length > max_text_length || length != usize(3 + alphabet_length + text_length) { return -1 }
		mut alphabet := [max_alphabet_length]i64{}
		mut result := [max_text_length]u8{}
		for i in 0 .. int(alphabet_length) {
			symbol := values[3 + i]
			if symbol < 0 || symbol > 127 { return -1 }
			for j in 0 .. i { if alphabet[j] == symbol { return -1 } }
			alphabet[i] = symbol
		}
		mut result_length := 0
		if mode == 0 {
			if text_length > 0 && alphabet_length == 0 { return -1 }
			for i in 0 .. int(text_length) {
				symbol := values[3 + int(alphabet_length) + i]
				if symbol < 0 || symbol > 127 { return -1 }
				mut position := 0
				for position < int(alphabet_length) && alphabet[position] != symbol { position++ }
				if position == int(alphabet_length) { return -1 }
				result[result_length] = u8(position)
				result_length++
				for position > 0 { alphabet[position] = alphabet[position - 1]; position-- }
				alphabet[0] = symbol
			}
		} else if alphabet_length > 0 {
			for i in 0 .. int(text_length) {
				index := values[3 + int(alphabet_length) + i]
				if index < 0 || index >= alphabet_length { return -1 }
				symbol := alphabet[int(index)]
				result[result_length] = u8(symbol)
				result_length++
				mut position := int(index)
				for position > 0 { alphabet[position] = alphabet[position - 1]; position-- }
				alphabet[0] = symbol
			}
		}
		if capacity < usize(result_length) || (result_length > 0 && output == nil) { return -2 }
		for i in 0 .. result_length { output[i] = result[i] }
		return i64(result_length)
	}
}
