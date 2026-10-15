module dynamic_array

const max_operations = 128
const max_elements = 64
const max_input_length = 1 + 3 * max_operations

fn write_i64_le(output &u8, word_index int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[word_index * 8 + byte] = u8((bits >> u64(byte * 8)) & 255) }
	}
}

@[export: 'dynamic_array']
pub fn dynamic_array(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 1 || length > max_input_length || unsafe { input == nil } { return -1 }
	unsafe {
		operation_count_value := input[0]
		if operation_count_value < 0 || operation_count_value > max_operations { return -1 }
		mut first := [max_elements]i64{init: 0}
		mut second := [max_elements]i64{init: 0}
		mut query_results := [max_operations]i64{init: 0}
		mut active_first := true
		mut size := 0
		mut capacity := 16
		mut cursor := 1
		mut query_count := 0
		for _ in 0 .. int(operation_count_value) {
			if cursor >= int(length) { return -1 }
			operation := input[cursor]
			cursor++
			if operation == 0 {
				if cursor >= int(length) || size >= max_elements { return -1 }
				value := input[cursor]
				cursor++
				if size == capacity {
					if active_first {
						for index in 0 .. size { second[index] = first[index] }
						active_first = false
					} else {
						for index in 0 .. size { first[index] = second[index] }
						active_first = true
					}
					capacity *= 2
				}
				if active_first { first[size] = value } else { second[size] = value }
				size++
			} else if operation == 1 {
				if cursor + 1 >= int(length) { return -1 }
				index_value := input[cursor]
				value := input[cursor + 1]
				cursor += 2
				if index_value < 0 || index_value >= i64(size) { return -1 }
				index := int(index_value)
				if active_first { first[index] = value } else { second[index] = value }
			} else if operation == 2 {
				if cursor >= int(length) || query_count >= max_operations { return -1 }
				index_value := input[cursor]
				cursor++
				if index_value < 0 || index_value >= i64(size) { return -1 }
				index := int(index_value)
				if active_first { query_results[query_count] = first[index] } else { query_results[query_count] = second[index] }
				query_count++
			} else if operation == 3 {
				if query_count >= max_operations { return -1 }
				query_results[query_count] = i64(size)
				query_count++
			} else {
				return -1
			}
		}
		if cursor != int(length) { return -1 }
		output_words := 2 + query_count + size
		output_bytes := usize(output_words * 8)
		if output_capacity < output_bytes { return -2 }
		write_i64_le(output, 0, i64(query_count))
		for index in 0 .. query_count { write_i64_le(output, index + 1, query_results[index]) }
		write_i64_le(output, query_count + 1, i64(size))
		for index in 0 .. size {
			value := if active_first { first[index] } else { second[index] }
			write_i64_le(output, query_count + 2 + index, value)
		}
		return i64(output_words)
	}
}
