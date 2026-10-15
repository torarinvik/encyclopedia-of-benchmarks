module hill_cipher_mod97_cpp

const alphabet = [97]i64{65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 126, 33, 64, 35, 36, 37, 94, 38, 42, 40, 41, 95, 43, 96, 45, 61, 91, 93, 123, 125, 124, 59, 39, 34, 58, 44, 46, 47, 60, 62, 63, 92, 13, 10, 32}
const encrypt_key = [4]i64{2, 5, 1, 6}
const decrypt_key = [4]i64{84, 27, 83, 28}

fn alphabet_index(value i64) int {
	for index in 0 .. 97 { if alphabet[index] == value { return index } }
	return -1
}

@[export: 'hill_cipher_mod97_cpp']
pub fn hill_cipher_mod97_cpp(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 3 || length > 258 || unsafe { values == nil } { return -1 }
	unsafe {
		operation, raw_length := values[0], values[1]
		if (operation != 0 && operation != 1) || raw_length < 1 || raw_length > 256 || length != usize(raw_length + 2) { return -1 }
		text_length := int(raw_length)
		mut indices := []u8{len: text_length, init: 0}
		for index in 0 .. text_length {
			mapped := alphabet_index(values[index + 2])
			if mapped < 0 { return -1 }
			indices[index] = u8(mapped)
		}
		output_length := text_length + text_length % 2
		if output == nil || output_capacity < usize(output_length) { return -2 }
		key := if operation == 0 { encrypt_key } else { decrypt_key }
		for offset in 0 .. output_length / 2 {
			position := offset * 2
			first, second := i64(indices[position]), i64(0)
			if position + 1 < text_length { second = i64(indices[position + 1]) }
			row0 := int((key[0] * first + key[1] * second) % 97)
			row1 := int((key[2] * first + key[3] * second) % 97)
			output[position], output[position + 1] = u8(alphabet[row0]), u8(alphabet[row1])
		}
		return i64(output_length)
	}
}
