const min_lists = 2
const max_lists = 8
const max_list_length = 32
const max_input_length = 266
const bytes_per_value = 4

fn store_i32_le(mut output &u8, position int, value i32) {
	bits := u32(value)
	for byte in 0 .. bytes_per_value {
		unsafe { output[position + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'inverted_list_svs_binary_search']
pub fn inverted_list_svs_binary_search(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < min_lists + 1 || length > max_input_length { return -1 }
	if unsafe { input[0] < min_lists || input[0] > max_lists } { return -1 }
	count := int(unsafe { input[0] })
	mut starts := [max_lists]int{}
	mut sizes := [max_lists]int{}
	mut order := [max_lists]int{}
	mut position := 1
	for list in 0 .. count {
		if position >= int(length) || unsafe { input[position] < 0 || input[position] > max_list_length } { return -1 }
		size := int(unsafe { input[position] }); position++
		if size > int(length) - position { return -1 }
		starts[list] = position; sizes[list] = size; order[list] = list
		for i in 0 .. size {
			value := unsafe { input[position + i] }
			if value < -2147483648 || value > 2147483647 { return -1 }
			if i > 0 && unsafe { input[position + i - 1] >= value } { return -1 }
		}
		position += size
	}
	if position != int(length) { return -1 }
	for i in 1 .. count {
		key := order[i]; mut j := i
		for j > 0 && sizes[order[j - 1]] > sizes[key] { order[j] = order[j - 1]; j-- }
		order[j] = key
	}
	maximum_result := sizes[order[0]]
	if output_capacity < usize(maximum_result * bytes_per_value) || (maximum_result > 0 && unsafe { output == nil }) { return -2 }
	mut candidates := [max_list_length]i32{}
	mut candidate_count := maximum_result
	for i in 0 .. candidate_count { candidates[i] = i32(unsafe { input[starts[order[0]] + i] }) }
	for rank in 1 .. count {
		if candidate_count == 0 { break }
		list := order[rank]; start := starts[list]; size := sizes[list]
		mut cursor := 0; mut kept := 0
		for i in 0 .. candidate_count {
			candidate := candidates[i]; mut low := cursor; mut high := size
			for low < high {
				middle := low + (high - low) / 2
				if unsafe { input[start + middle] < i64(candidate) } { low = middle + 1 } else { high = middle }
			}
			if low < size && unsafe { input[start + low] == i64(candidate) } {
				candidates[kept] = candidate; kept++; cursor = low + 1
			} else { cursor = low }
		}
		candidate_count = kept
	}
	for i in 0 .. candidate_count { store_i32_le(mut output, i * bytes_per_value, candidates[i]) }
	return i64(candidate_count)
}
