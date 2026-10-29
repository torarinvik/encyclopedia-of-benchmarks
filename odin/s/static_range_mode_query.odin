package static_range_mode_query

import "core:c"

MAX_N :: 32
MAX_Q :: 16
MAX_BLOCKS :: 6
MAX_INPUT_LENGTH :: 66

lower_bound_i64 :: proc(values: [^]i64, count: int, target: i64) -> int {
	begin, end := 0, count
	for begin < end {
		middle := begin + (end-begin)/2
		if values[middle] < target { begin = middle+1 } else { end = middle }
	}
	return begin
}

lower_bound_int :: proc(values: [^]int, begin_value, end_value, target: int) -> int {
	begin, end := begin_value, end_value
	for begin < end {
		middle := begin + (end-begin)/2
		if values[middle] < target { begin = middle+1 } else { end = middle }
	}
	return begin
}

range_frequency :: proc(occurrences: [^]int, offsets: [^]int,
		id, left, right: int) -> int {
	begin, end := offsets[id], offsets[id+1]
	return lower_bound_int(occurrences, begin, end, right) -
		lower_bound_int(occurrences, begin, end, left)
}

write_i64 :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8((bits >> (8*byte)) & 0xff)
	}
}

@(export)
static_range_mode_query :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	n_value, q_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q do return -1
	n, q := int(n_value), int(q_value)
	if length != c.size_t(2+n+2*q) do return -1
	for index := 0; index < n; index += 1 {
		if input[2+index] < 0 || input[2+index] > 1_000_000_000 do return -1
	}
	for query := 0; query < q; query += 1 {
		left, right := input[2+n+2*query], input[3+n+2*query]
		if left < 0 || right <= left || right > n_value do return -1
	}
	if output == nil || output_capacity < c.size_t(16*q) do return -2

	sorted: [MAX_N]i64
	unique_values: [MAX_N]i64
	compressed: [MAX_N]int
	frequencies: [MAX_N]int
	offsets: [MAX_N+1]int
	cursor: [MAX_N]int
	occurrences: [MAX_N]int
	block_mode: [MAX_BLOCKS*MAX_BLOCKS]int
	for index := 0; index < n; index += 1 {
		value := input[2+index]
		position := index
		for position > 0 && sorted[position-1] > value {
			sorted[position] = sorted[position-1]
			position -= 1
		}
		sorted[position] = value
	}
	distinct := 0
	for index := 0; index < n; index += 1 {
		if distinct == 0 || sorted[index] != unique_values[distinct-1] {
			unique_values[distinct] = sorted[index]
			distinct += 1
		}
	}
	for index := 0; index < n; index += 1 {
		id := lower_bound_i64(&unique_values[0], distinct, input[2+index])
		compressed[index] = id
		frequencies[id] += 1
	}
	for id := 0; id < distinct; id += 1 { offsets[id+1] = offsets[id] + frequencies[id] }
	for id := 0; id < distinct; id += 1 { cursor[id] = offsets[id] }
	for index := 0; index < n; index += 1 {
		id := compressed[index]
	occurrences[cursor[id]] = index
		cursor[id] += 1
	}

	block_size := 1
	for block_size*block_size < n { block_size += 1 }
	block_count := (n+block_size-1)/block_size
	frequency: [MAX_N]int
	for first := 0; first < block_count; first += 1 {
		for id := 0; id < distinct; id += 1 { frequency[id] = 0 }
		best_id, best_count := 0, 0
		for last := first; last < block_count; last += 1 {
			begin, end := last*block_size, (last+1)*block_size
			if end > n { end = n }
			for index := begin; index < end; index += 1 {
				id := compressed[index]
				frequency[id] += 1
				count := frequency[id]
				if count > best_count || (count == best_count && id < best_id) {
					best_id, best_count = id, count
				}
			}
			block_mode[first*MAX_BLOCKS+last] = best_id
		}
	}

	for query := 0; query < q; query += 1 {
		left, right := int(input[2+n+2*query]), int(input[3+n+2*query])
		first_full := (left+block_size-1)/block_size
		after_full := right/block_size
		best_id, best_count := 0, 0
		if first_full < after_full {
			best_id = block_mode[first_full*MAX_BLOCKS+after_full-1]
			best_count = range_frequency(&occurrences[0], &offsets[0], best_id, left, right)
			span_start, span_end := first_full*block_size, after_full*block_size
			for index := left; index < span_start; index += 1 {
				id := compressed[index]
				count := range_frequency(&occurrences[0], &offsets[0], id, left, right)
				if count > best_count || (count == best_count && id < best_id) { best_id, best_count = id, count }
			}
			for index := span_end; index < right; index += 1 {
				id := compressed[index]
				count := range_frequency(&occurrences[0], &offsets[0], id, left, right)
				if count > best_count || (count == best_count && id < best_id) { best_id, best_count = id, count }
			}
		} else {
			for index := left; index < right; index += 1 {
				id := compressed[index]
				count := range_frequency(&occurrences[0], &offsets[0], id, left, right)
				if count > best_count || (count == best_count && id < best_id) { best_id, best_count = id, count }
			}
		}
		write_i64(output, 16*query, unique_values[best_id])
		write_i64(output, 16*query+8, i64(best_count))
	}
	return i64(16*q)
}
