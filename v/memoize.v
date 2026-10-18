fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte_index in 0 .. 8 {
		output[offset + byte_index] = u8((bits >> (byte_index * 8)) & u64(0xff))
	}
}

@[export: 'memoize']
pub fn memoize(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > 259 { return -1 }
		if input[0] < 0 || input[0] > 4 || input[1] < 0 || input[1] > 64 { return -1 }
		arity := int(input[0])
		call_count := int(input[1])
		if input_length != usize(2 + arity * call_count) { return -1 }
		for index in 0 .. arity * call_count {
			value := input[2 + index]
			if value < -100 || value > 100 { return -1 }
		}

		mut keys := [64][4]i64{}
		mut key_results := [64]i64{}
		mut key_count := 0
		mut results := [65]i64{}
		for call_index in 0 .. call_count {
			start := 2 + call_index * arity
			mut key := [4]i64{}
			mut encoded := i64(0)
			for argument_index in 0 .. arity {
				value := input[start + argument_index]
				key[argument_index] = value
				encoded = encoded * 201 + value + 100
			}
			mut found := -1
			for previous in 0 .. key_count {
				mut equal := true
				for argument_index in 0 .. arity {
					if keys[previous][argument_index] != key[argument_index] { equal = false }
				}
				if equal { found = previous; break }
			}
			if found >= 0 {
				results[call_index] = key_results[found]
			} else {
				keys[key_count] = key
				key_results[key_count] = encoded
				key_count++
				results[call_index] = encoded
			}
		}
		results[call_count] = i64(key_count)

		output_bytes := 8 * (call_count + 1)
		mut staged := [520]u8{}
		for index in 0 .. call_count + 1 { put_i64_le(mut staged[0], index * 8, results[index]) }
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. output_bytes { output[index] = staged[index] }
		return i64(output_bytes)
	}
}
