const max_block_count = 16
const max_process_count = 32
const max_input_length = 52
const max_output_bytes = 256
const no_allocation = i64(-255)

fn put_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'memory_management_algorithms']
pub fn memory_management_algorithms(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > max_input_length { return -1 }
		policy := input[0]
		if policy < 0 || policy > 3 || input[1] < 1 || input[1] > max_block_count || input[2] < 0 || input[2] > max_process_count { return -1 }
		block_count := int(input[1])
		process_count := int(input[2])
		if input_length != usize(3 + block_count + process_count) { return -1 }

		mut blocks := [max_block_count]i64{}
		mut processes := [max_process_count]i64{}
		for index in 0 .. block_count {
			size := input[3 + index]
			if size < 1 || size > 10000 { return -1 }
			blocks[index] = size
		}
		for index in 0 .. process_count {
			size := input[3 + block_count + index]
			if size < 1 || size > 10000 { return -1 }
			processes[index] = size
		}

		mut allocations := [max_process_count]i64{}
		mut next_fit_counter := i64(0)
		for process_index in 0 .. process_count {
			process := processes[process_index]
			mut selected := no_allocation
			if policy == 0 {
				for index in 0 .. block_count {
					if blocks[index] >= process { selected = i64(index); break }
				}
			} else if policy == 1 {
				mut min_diff := blocks[0]
				for index in 1 .. block_count { if blocks[index] > min_diff { min_diff = blocks[index] } }
				for index in 0 .. block_count {
					difference := blocks[index] - process
					if difference < min_diff && difference >= 0 {
						min_diff = difference
						selected = i64(index)
					}
				}
			} else if policy == 2 {
				mut best := 0
				for candidate in 1 .. block_count { if blocks[candidate] > blocks[best] { best = candidate } }
				if blocks[best] >= process { selected = i64(best) }
			} else {
				mut found := false
				for offset in 0 .. block_count {
					if next_fit_counter + i64(offset) >= i64(block_count) { next_fit_counter = -i64(offset) }
					index := int(i64(offset) + next_fit_counter)
					if blocks[index] >= process {
						next_fit_counter += i64(offset)
						selected = next_fit_counter
						found = true
						break
					}
				}
				if !found { next_fit_counter += i64(block_count) }
			}
			allocations[process_index] = selected
			if selected != no_allocation { blocks[int(selected)] -= process }
		}

		output_bytes := process_count * 8
		if output_bytes > max_output_bytes { return -1 }
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. process_count { put_i64_le(mut output, index * 8, allocations[index]) }
		return i64(output_bytes)
	}
}
