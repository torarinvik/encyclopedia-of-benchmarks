const max_items = 4096
const max_codes = 4352
const max_output = 65536
const fnv_offset = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)

fn hash_i64(mut hash u64, value i64) u64 {
	bits := u64(value)
	for shift in 0 .. 8 { hash = (hash ^ u64(u8(bits >> (shift * 8)))) * fnv_prime }
	return hash
}

fn hash_record(mode i64, values &i64, count int) i64 {
	mut hash := hash_i64(fnv_offset, mode)
	hash = hash_i64(hash, i64(count))
	for i in 0 .. count { hash = hash_i64(hash, unsafe { values[i] }) }
	return i64(hash & u64(0x7fffffffffffffff))
}

fn expand_code(code int, dictionary_size int, prefix &i32, suffix &u8, mut phrase &u8) int {
	mut length := 0
	mut current := code
	for current >= 256 {
		if current >= dictionary_size || length >= max_codes { return -1 }
		unsafe { phrase[length] = suffix[current] }
		length++
		parent := unsafe { prefix[current] }
		if parent < 0 { return -1 }
		current = int(parent)
	}
	if current < 0 || current > 255 || length >= max_codes { return -1 }
	unsafe { phrase[length] = u8(current) }
	length++
	mut left := 0
	mut right := length - 1
	for left < right {
		byte := unsafe { phrase[left] }
		unsafe { phrase[left] = phrase[right]; phrase[right] = byte }
		left++
		right--
	}
	return length
}

@[export: 'lzw']
pub fn lzw(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_items + 2 { return -1 }
	mode := unsafe { input[0] }
	count64 := unsafe { input[1] }
	if (mode != 0 && mode != 1) || count64 < 0 || count64 > max_items || length != usize(count64 + 2) { return -1 }
	count := int(count64)

	mut prefix := [max_codes]i32{}
	mut next_sibling := [max_codes]i32{}
	mut first_child := [max_codes]i32{}
	mut suffix := [max_codes]u8{}
	mut first_symbol := [max_codes]u8{}
	for i in 0 .. max_codes { prefix[i] = -1; next_sibling[i] = -1; first_child[i] = -1 }
	for code in 0 .. 256 { suffix[code] = u8(code); first_symbol[code] = u8(code) }

	if mode == 0 {
		for i in 0 .. count {
			value := unsafe { input[2 + i] }
			if value < 0 || value > 127 { return -1 }
		}
		mut codes := [max_items]i64{}
		mut code_count := 0
		if count > 0 {
			mut dictionary_size := 256
			mut current := int(unsafe { input[2] })
			for i in 1 .. count {
				byte := u8(unsafe { input[2 + i] })
				mut match_code := int(first_child[current])
				for match_code >= 0 && suffix[match_code] != byte { match_code = int(next_sibling[match_code]) }
				if match_code >= 0 {
					current = match_code
				} else {
					codes[code_count] = i64(current)
					code_count++
					if dictionary_size >= max_codes { return -1 }
					prefix[dictionary_size] = i32(current)
					suffix[dictionary_size] = byte
					first_symbol[dictionary_size] = first_symbol[current]
					next_sibling[dictionary_size] = first_child[current]
					first_child[current] = i32(dictionary_size)
					dictionary_size++
					current = int(byte)
				}
			}
			codes[code_count] = i64(current)
			code_count++
		}
		return hash_record(0, &codes[0], code_count)
	}

	for i in 0 .. count {
		value := unsafe { input[2 + i] }
		if value < 0 || value >= max_codes { return -1 }
	}
	if count == 0 { return hash_record(1, unsafe { input }, 0) }
	first_code := int(unsafe { input[2] })
	if first_code > 127 { return -1 }
	mut decoded := [max_output]u8{}
	mut phrase := [max_codes]u8{}
	decoded[0] = u8(first_code)
	mut decoded_length := 1
	mut dictionary_size := 256
	mut previous := first_code
	for i in 1 .. count {
		code := int(unsafe { input[2 + i] })
		mut phrase_length := 0
		if code < dictionary_size {
			phrase_length = expand_code(code, dictionary_size, &prefix[0], &suffix[0], mut &phrase[0])
			if phrase_length < 0 { return -1 }
		} else if code == dictionary_size {
			phrase_length = expand_code(previous, dictionary_size, &prefix[0], &suffix[0], mut &phrase[0])
			if phrase_length < 0 || phrase_length >= max_codes { return -1 }
			phrase[phrase_length] = first_symbol[previous]
			phrase_length++
		} else { return -1 }
		if decoded_length > max_output - phrase_length { return -1 }
		for j in 0 .. phrase_length { if phrase[j] > 127 { return -1 } }
		for j in 0 .. phrase_length { decoded[decoded_length] = phrase[j]; decoded_length++ }
		if dictionary_size >= max_codes { return -1 }
		next_byte := if code == dictionary_size { first_symbol[previous] } else { first_symbol[code] }
		prefix[dictionary_size] = i32(previous)
		suffix[dictionary_size] = next_byte
		first_symbol[dictionary_size] = first_symbol[previous]
		dictionary_size++
		previous = code
	}
	mut hash := hash_i64(fnv_offset, 1)
	hash = hash_i64(hash, i64(decoded_length))
	for i in 0 .. decoded_length { hash = hash_i64(hash, i64(decoded[i])) }
	return i64(hash & u64(0x7fffffffffffffff))
}
