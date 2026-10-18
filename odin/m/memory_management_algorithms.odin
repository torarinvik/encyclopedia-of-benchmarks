package memory_management_algorithms

import "core:c"

MAX_BLOCK_COUNT :: 16
MAX_PROCESS_COUNT :: 32
MAX_INPUT_LENGTH :: 52
MAX_OUTPUT_BYTES :: 256
NO_ALLOCATION :: i64(-255)

put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> u64(8 * byte)) & 255) }
}

@(export)
memory_management_algorithms :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > MAX_INPUT_LENGTH do return -1
	policy := input[0]
	if policy < 0 || policy > 3 || input[1] < 1 || input[1] > MAX_BLOCK_COUNT ||
		input[2] < 0 || input[2] > MAX_PROCESS_COUNT do return -1
	block_count := int(input[1])
	process_count := int(input[2])
	if input_length != c.size_t(3 + block_count + process_count) do return -1

	blocks: [MAX_BLOCK_COUNT]i64
	processes: [MAX_PROCESS_COUNT]i64
	for index := 0; index < block_count; index += 1 {
		size := input[3 + index]
		if size < 1 || size > 10000 do return -1
		blocks[index] = size
	}
	for index := 0; index < process_count; index += 1 {
		size := input[3 + block_count + index]
		if size < 1 || size > 10000 do return -1
		processes[index] = size
	}

	allocations: [MAX_PROCESS_COUNT]i64
	next_fit_counter: i64 = 0
	for process_index := 0; process_index < process_count; process_index += 1 {
		process := processes[process_index]
		selected := NO_ALLOCATION
		if policy == 0 {
			for index := 0; index < block_count; index += 1 {
				if blocks[index] >= process { selected = i64(index); break }
			}
		} else if policy == 1 {
			min_diff := blocks[0]
			for index := 1; index < block_count; index += 1 { if blocks[index] > min_diff do min_diff = blocks[index] }
			for index := 0; index < block_count; index += 1 {
				difference := blocks[index] - process
				if difference < min_diff && difference >= 0 { min_diff = difference; selected = i64(index) }
			}
		} else if policy == 2 {
			best := 0
			for candidate := 1; candidate < block_count; candidate += 1 { if blocks[candidate] > blocks[best] do best = candidate }
			if blocks[best] >= process do selected = i64(best)
		} else {
			found := false
			for offset := 0; offset < block_count; offset += 1 {
				if next_fit_counter + i64(offset) >= i64(block_count) do next_fit_counter = -i64(offset)
				index := int(i64(offset) + next_fit_counter)
				if blocks[index] >= process {
					next_fit_counter += i64(offset)
					selected = next_fit_counter
					found = true
					break
				}
			}
			if !found do next_fit_counter += i64(block_count)
		}
		allocations[process_index] = selected
		if selected != NO_ALLOCATION do blocks[int(selected)] -= process
	}

	output_bytes := process_count * 8
	if output_bytes > MAX_OUTPUT_BYTES do return -1
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < process_count; index += 1 { put_i64_le(output, index * 8, allocations[index]) }
	return i64(output_bytes)
}
