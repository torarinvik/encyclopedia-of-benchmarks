module onepad_cipher

const max_text_length = 1024

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'onepad_cipher']
pub fn onepad_cipher(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 2 || length > 2 + 2 * max_text_length { return -1 }
	mode := unsafe { input[0] }
	count_value := unsafe { input[1] }
	if (mode != 0 && mode != 1) || count_value < 0 || count_value > max_text_length { return -1 }
	count := int(count_value)
	if int(length) != 2 + 2 * count { return -1 }
	needed := if mode == 0 { 8 * count } else { count }
	if output_capacity < usize(needed) { return -2 }
	for index in 0 .. count {
		data := unsafe { input[2 + index] }
		key := unsafe { input[2 + count + index] }
		if key < 1 || key > 300 { return -1 }
		if mode == 0 {
			if data < 32 || data > 126 { return -1 }
			store_i64_le(mut output, 8 * index, (data + key) * key)
		} else {
			key_square := key * key
			if data < key_square || (data - key_square) % key != 0 { return -1 }
			plain := (data - key_square) / key
			if plain < 32 || plain > 126 { return -1 }
			unsafe { output[index] = u8(plain) }
		}
	}
	return i64(needed)
}
