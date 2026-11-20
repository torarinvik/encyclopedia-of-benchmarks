const max_cards = 12
const max_input_words = 14
const deck_size = 81

fn complement_code(a_raw i8, b_raw i8) int {
	a := int(a_raw)
	b := int(b_raw)
	mut place := 1
	mut result := 0
	for _ in 0 .. 4 {
		digit_sum := (a / place) % 3 + (b / place) % 3
		result += ((3 - digit_sum % 3) % 3) * place
		place *= 3
	}
	return result
}

fn put_i64_le(mut output &u8, word int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[word * 8 + byte] = u8(bits >> (8 * byte)) }
	}
}

@[export: 'set_puzzle_find_sets']
pub fn set_puzzle_find_sets(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 1 || length > max_input_words { return -1 }
	unsafe {
		if input == nil { return -1 }
		raw_count := input[0]
		if raw_count < 0 || raw_count > max_cards || length != usize(raw_count + 1) { return -1 }

		mut index_by_code := [81]i8{init: -1}
		mut code_by_index := [12]i8{init: 0}
		count := int(raw_count)
		for i in 0 .. count {
			code := input[i + 1]
			if code < 0 || code >= deck_size { return -1 }
			if index_by_code[int(code)] >= 0 { return -1 }
			index_by_code[int(code)] = i8(i)
			code_by_index[i] = i8(code)
		}

		mut set_count := 0
		for i in 0 .. count {
			for j := i + 1; j < count; j++ {
				k := index_by_code[complement_code(code_by_index[i], code_by_index[j])]
				if k > i8(j) { set_count++ }
			}
		}
		output_bytes := (1 + 3 * set_count) * 8
		if output == nil || capacity < usize(output_bytes) { return -2 }

		put_i64_le(mut output, 0, i64(set_count))
		mut word := 1
		for i in 0 .. count {
			for j := i + 1; j < count; j++ {
				k := index_by_code[complement_code(code_by_index[i], code_by_index[j])]
				if k > i8(j) {
					put_i64_le(mut output, word, i64(i))
					put_i64_le(mut output, word + 1, i64(j))
					put_i64_le(mut output, word + 2, i64(k))
					word += 3
				}
			}
		}
		return i64(output_bytes)
	}
}
