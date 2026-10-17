module sqrt_decomposition_range_sum

const (
	max_n = 64
	max_operations = 64
	max_input_length = 258
)

fn block_size_for(n int) int {
	mut block_size := 1
	for (block_size + 1) * (block_size + 1) <= n {
		block_size++
	}
	return block_size
}

fn query_sum(elements []i64, blocks []i64, block_size int, start int, ending int) i64 {
	first_index_next_block := ((start / block_size) + 1) * block_size
	mut sum := elements[start]
	if first_index_next_block > ending {
		for index := start + 1; index < ending; index++ {
			sum += elements[index]
		}
	} else {
		for index := start + 1; index < first_index_next_block; index++ {
			sum += elements[index]
		}
		end_block := ending / block_size
		for block := first_index_next_block / block_size; block < end_block; block++ {
			sum += blocks[block]
		}
		for index := end_block * block_size; index < ending; index++ {
			sum += elements[index]
		}
	}
	return sum
}

@[export: 'sqrt_decomposition_range_sum']
pub fn sqrt_decomposition_range_sum(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 3 || length > max_input_length {
		return -1
	}
	n_arg := unsafe { input[0] }
	if n_arg < 1 || n_arg > max_n {
		return -1
	}
	n := int(n_arg)
	if length < n + 2 {
		return -1
	}
	operation_count_arg := unsafe { input[n + 1] }
	if operation_count_arg < 0 || operation_count_arg > max_operations {
		return -1
	}
	operation_count := int(operation_count_arg)
	if length != 2 + n + 3 * operation_count {
		return -1
	}

	mut elements := []i64{len: n}
	for index in 0 .. n {
		value := unsafe { input[index + 1] }
		if value < -1000 || value > 1000 {
			return -1
		}
		elements[index] = value
	}
	operations_start := n + 2
	mut query_count := 0
	for operation in 0 .. operation_count {
		offset := operations_start + 3 * operation
		kind := unsafe { input[offset] }
		first := unsafe { input[offset + 1] }
		second := unsafe { input[offset + 2] }
		if kind == 0 {
			if first < 0 || first >= second || second > n_arg {
				return -1
			}
			query_count++
		} else if kind == 1 {
			if first < 0 || first >= n_arg || second < -1000 || second > 1000 {
				return -1
			}
		} else {
			return -1
		}
	}

	output_bytes := query_count * 8
	if output == nil || capacity < output_bytes {
		return -2
	}
	block_size := block_size_for(n)
	mut blocks := []i64{len: n}
	for index in 0 .. n {
		block := index / block_size
		if index % block_size == 0 {
			blocks[block] = elements[index]
		} else {
			blocks[block] += elements[index]
		}
	}

	mut output_offset := 0
	for operation in 0 .. operation_count {
		offset := operations_start + 3 * operation
		kind := unsafe { input[offset] }
		first := unsafe { input[offset + 1] }
		second := unsafe { input[offset + 2] }
		if kind == 0 {
			sum := query_sum(elements, blocks, block_size, int(first), int(second))
			mut bits := u64(sum)
			for byte in 0 .. 8 {
				unsafe { output[output_offset + byte] = u8(bits & 255) }
				bits >>= 8
			}
			output_offset += 8
		} else {
			index := int(first)
			block := index / block_size
			blocks[block] = blocks[block] - elements[index] + second
			elements[index] = second
		}
	}
	return i64(output_bytes)
}
