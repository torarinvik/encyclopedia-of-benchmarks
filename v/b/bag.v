const max_inserts = 128
const max_queries = 64

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'bag']
pub fn bag(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if isnil(input) || length < 2 { return -1 }
	insert_count_value := unsafe { input[0] }
	if insert_count_value < 0 || insert_count_value > max_inserts { return -1 }
	insert_count := int(insert_count_value)
	if length < usize(insert_count + 2) { return -1 }
	query_count_value := unsafe { input[insert_count + 1] }
	if query_count_value < 0 || query_count_value > max_queries { return -1 }
	query_count := int(query_count_value)
	if length != usize(insert_count + query_count + 2) { return -1 }

	for index in 0 .. insert_count {
		value := unsafe { input[index + 1] }
		if value < -2147483648 || value > 2147483647 { return -1 }
	}
	for query in 0 .. query_count {
		value := unsafe { input[insert_count + query + 2] }
		if value < -2147483648 || value > 2147483647 { return -1 }
	}
	output_length := (query_count + 2) * 8
	if isnil(output) || capacity < usize(output_length) { return -2 }

	mut values := [max_inserts]i64{}
	mut distinct_count := 0
	for index in 0 .. insert_count {
		value := unsafe { input[index + 1] }
		mut node := 0
		for node < distinct_count && values[node] != value { node++ }
		if node == distinct_count {
			values[node] = value
			distinct_count++
		}
	}

	put_i64_le(mut output, 0, insert_count_value)
	put_i64_le(mut output, 8, if insert_count == 0 { i64(1) } else { i64(0) })
	for query in 0 .. query_count {
		target := unsafe { input[insert_count + query + 2] }
		mut contains := i64(0)
		for node in 0 .. distinct_count {
			if values[node] == target { contains = 1 }
		}
		put_i64_le(mut output, (query + 2) * 8, contains)
	}
	return i64(output_length)
}
