module transposition

const max_key = 32
const max_text = 512
const max_input = 3 + max_key + max_text
const max_padded = max_text + max_key

fn hash_byte(hash_value u64, byte u8) u64 {
	return (hash_value ^ u64(byte)) * u64(1099511628211)
}

fn output_hash(text &u8, length int) i64 {
	mut hash := u64(14695981039346656037)
	count := u64(length)
	for index in 0 .. 8 { hash = hash_byte(hash, u8((count >> (index * 8)) & 255)) }
	for index in 0 .. length {
		codepoint := u32(unsafe { text[index] })
		for byte_index in 0 .. 4 { hash = hash_byte(hash, u8((codepoint >> (byte_index * 8)) & 255)) }
	}
	return i64(hash & u64(0x7fffffffffffffff))
}

@[export: 'transposition']
pub fn transposition(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input { return -1 }
	mode := unsafe { input[0] }
	key_length_value := unsafe { input[1] }
	if (mode != 0 && mode != 1) || key_length_value < 1 || key_length_value > max_key { return -1 }
	key_length := int(key_length_value)
	text_length_index := 2 + key_length
	if length <= usize(text_length_index) { return -1 }
	text_length_value := unsafe { input[text_length_index] }
	if text_length_value < 1 || text_length_value > max_text { return -1 }
	text_length := int(text_length_value)
	if length != usize(text_length_index + 1 + text_length) { return -1 }

	mut key := [max_key]u8{init: 0}
	mut sorted := [max_key]u8{init: 0}
	for index in 0 .. key_length {
		value := unsafe { input[2 + index] }
		if !((value >= 65 && value <= 90) || (value >= 97 && value <= 122)) { return -1 }
		mut ch := u8(value)
		if ch >= 65 && ch <= 90 { ch += 32 }
		key[index] = ch
		sorted[index] = ch
	}
	for index in 1 .. key_length {
		value := sorted[index]
		mut cursor := index
		for cursor > 0 && sorted[cursor - 1] > value {
			sorted[cursor] = sorted[cursor - 1]
			cursor--
		}
		sorted[cursor] = value
	}
	mut ranks := [max_key]int{init: 0}
	for index in 0 .. key_length {
		mut first := 0
		for first < key_length && sorted[first] != key[index] { first++ }
		mut duplicate := 0
		for prior in 0 .. index { if key[prior] == key[index] { duplicate++ } }
		ranks[index] = first + duplicate + 1
	}
	mut text := [max_padded]u8{init: 0}
	for index in 0 .. text_length {
		value := unsafe { input[text_length_index + 1 + index] }
		if value < 32 || value > 126 { return -1 }
		text[index] = u8(value)
	}
	if mode == 0 && text[text_length - 1] == 32 { return -1 }
	padded_length := text_length + key_length - text_length % key_length
	for index in text_length .. padded_length { text[index] = 32 }
	mut result := [max_padded]u8{init: 0}
	mut result_length := 0
	if mode == 0 {
		for start := 0; start < padded_length; start += key_length {
			mut block := [max_key]u8{init: 0}
			for offset in 0 .. key_length { block[ranks[offset] - 1] = text[start + offset] }
			for offset in 0 .. key_length { result[result_length] = block[offset]; result_length++ }
		}
	} else {
		for start := 0; start < text_length; start += key_length {
			for offset in 0 .. key_length { result[result_length] = text[start + ranks[offset] - 1]; result_length++ }
		}
		for result_length > 0 && result[result_length - 1] == 32 { result_length-- }
	}
	return output_hash(unsafe { &result[0] }, result_length)
}
