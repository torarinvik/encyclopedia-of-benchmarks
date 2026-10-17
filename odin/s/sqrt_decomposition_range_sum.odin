package sqrt_decomposition_range_sum

import "core:c"

MAX_N :: 64
MAX_OPERATIONS :: 64
MAX_INPUT_LENGTH :: 258

block_size_for :: proc(n: int) -> int {
	block_size := 1
	for (block_size + 1) * (block_size + 1) <= n {
		block_size += 1
	}
	return block_size
}

query_sum :: proc(elements, blocks: [^]i64, block_size, start, ending: int) -> i64 {
	first_index_next_block := ((start / block_size) + 1) * block_size
	sum := elements[start]
	if first_index_next_block > ending {
		for index := start + 1; index < ending; index += 1 {
			sum += elements[index]
		}
	} else {
		for index := start + 1; index < first_index_next_block; index += 1 {
			sum += elements[index]
		}
		end_block := ending / block_size
		for block := first_index_next_block / block_size; block < end_block; block += 1 {
			sum += blocks[block]
		}
		for index := end_block * block_size; index < ending; index += 1 {
			sum += elements[index]
		}
	}
	return sum
}

@(export, link_name="sqrt_decomposition_range_sum")
sqrt_decomposition_range_sum :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_arg := input[0]
	if n_arg < 1 || n_arg > MAX_N do return -1
	n := int(n_arg)
	if length < c.size_t(n + 2) do return -1
	operation_count_arg := input[n + 1]
	if operation_count_arg < 0 || operation_count_arg > MAX_OPERATIONS do return -1
	operation_count := int(operation_count_arg)
	if length != c.size_t(2 + n + 3 * operation_count) do return -1

	elements: [MAX_N]i64
	for index := 0; index < n; index += 1 {
		value := input[index + 1]
		if value < -1000 || value > 1000 do return -1
		elements[index] = value
	}
	operations_start := n + 2
	query_count := 0
	for operation := 0; operation < operation_count; operation += 1 {
		offset := operations_start + 3 * operation
		kind, first, second := input[offset], input[offset + 1], input[offset + 2]
		if kind == 0 {
			if first < 0 || first >= second || second > n_arg do return -1
			query_count += 1
		} else if kind == 1 {
			if first < 0 || first >= n_arg || second < -1000 || second > 1000 do return -1
		} else {
			return -1
		}
	}

	output_bytes := c.size_t(query_count * 8)
	if output == nil || capacity < output_bytes do return -2
	block_size := block_size_for(n)
	blocks: [MAX_N]i64
	for index := 0; index < n; index += 1 {
		block := index / block_size
		if index % block_size == 0 do blocks[block] = elements[index]
		else do blocks[block] += elements[index]
	}

	output_offset := 0
	for operation := 0; operation < operation_count; operation += 1 {
		offset := operations_start + 3 * operation
		kind, first, second := input[offset], input[offset + 1], input[offset + 2]
		if kind == 0 {
			sum := query_sum(&elements[0], &blocks[0], block_size, int(first), int(second))
			bits := transmute(u64)(sum)
			for byte := 0; byte < 8; byte += 1 {
				output[output_offset + byte] = u8(bits & 255)
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
