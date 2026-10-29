module static_range_mode_query

const max_n = 32
const max_q = 16
const max_blocks = 6
const max_input_length = 66

fn lower_bound_i64(values []i64, count int, target i64) int {
	mut begin := 0
	mut end := count
	for begin < end {
		middle := begin + (end - begin) / 2
		if values[middle] < target { begin = middle + 1 } else { end = middle }
	}
	return begin
}

fn lower_bound_int(values []int, begin_value int, end_value int, target int) int {
	mut begin := begin_value
	mut end := end_value
	for begin < end {
		middle := begin + (end - begin) / 2
		if values[middle] < target { begin = middle + 1 } else { end = middle }
	}
	return begin
}

fn range_frequency(occurrences []int, offsets []int, id int, left int, right int) int {
	begin := offsets[id]
	end := offsets[id + 1]
	return lower_bound_int(occurrences, begin, end, right) - lower_bound_int(occurrences, begin, end, left)
}

fn write_i64(output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 0xff) }
	}
}

@[export: 'static_range_mode_query']
pub fn static_range_mode_query(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if input == nil || length < 2 || length > max_input_length { return -1 }
	n_value := unsafe { input[0] }
	q_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_n || q_value < 1 || q_value > max_q { return -1 }
	n := int(n_value)
	q := int(q_value)
	if length != usize(2 + n + 2*q) { return -1 }
	for index in 0 .. n {
		value := unsafe { input[2 + index] }
		if value < 0 || value > 1_000_000_000 { return -1 }
	}
	for query in 0 .. q {
		left := unsafe { input[2 + n + 2*query] }
		right := unsafe { input[3 + n + 2*query] }
		if left < 0 || right <= left || right > n_value { return -1 }
	}
	if output == nil || output_capacity < usize(16*q) { return -2 }

	mut sorted := [32]i64{}
	mut unique_values := [32]i64{}
	mut compressed := [32]int{}
	mut frequencies := [32]int{}
	mut offsets := [33]int{}
	mut cursor := [32]int{}
	mut occurrences := [32]int{}
	mut block_mode := [36]int{}
	for index in 0 .. n {
		value := unsafe { input[2 + index] }
		mut position := index
		for position > 0 && sorted[position - 1] > value {
			sorted[position] = sorted[position - 1]
			position--
		}
		sorted[position] = value
	}
	mut distinct := 0
	for index in 0 .. n {
		if distinct == 0 || sorted[index] != unique_values[distinct - 1] {
			unique_values[distinct] = sorted[index]
			distinct++
		}
	}
	for index in 0 .. n {
		value := unsafe { input[2 + index] }
		id := lower_bound_i64(unique_values[..distinct], distinct, value)
		compressed[index] = id
		frequencies[id]++
	}
	for id in 0 .. distinct { offsets[id + 1] = offsets[id] + frequencies[id] }
	for id in 0 .. distinct { cursor[id] = offsets[id] }
	for index in 0 .. n {
		id := compressed[index]
		occurrences[cursor[id]] = index
		cursor[id]++
	}

	mut block_size := 1
	for block_size * block_size < n { block_size++ }
	block_count := (n + block_size - 1) / block_size
	mut frequency := [32]int{}
	for first in 0 .. block_count {
		for id in 0 .. distinct { frequency[id] = 0 }
		mut best_id := 0
		mut best_count := 0
		for last in first .. block_count {
			begin := last * block_size
			mut end := begin + block_size
			if end > n { end = n }
			for index in begin .. end {
				id := compressed[index]
				frequency[id]++
				count := frequency[id]
				if count > best_count || (count == best_count && id < best_id) {
					best_id = id
					best_count = count
				}
			}
			block_mode[first * max_blocks + last] = best_id
		}
	}

	for query in 0 .. q {
		left := int(unsafe { input[2 + n + 2*query] })
		right := int(unsafe { input[3 + n + 2*query] })
		first_full := (left + block_size - 1) / block_size
		after_full := right / block_size
		mut best_id := 0
		mut best_count := 0
		if first_full < after_full {
			best_id = block_mode[first_full * max_blocks + after_full - 1]
			best_count = range_frequency(occurrences[..], offsets[..], best_id, left, right)
			span_start := first_full * block_size
			span_end := after_full * block_size
			for index in left .. span_start {
				id := compressed[index]
				count := range_frequency(occurrences[..], offsets[..], id, left, right)
				if count > best_count || (count == best_count && id < best_id) { best_id = id; best_count = count }
			}
			for index in span_end .. right {
				id := compressed[index]
				count := range_frequency(occurrences[..], offsets[..], id, left, right)
				if count > best_count || (count == best_count && id < best_id) { best_id = id; best_count = count }
			}
		} else {
			for index in left .. right {
				id := compressed[index]
				count := range_frequency(occurrences[..], offsets[..], id, left, right)
				if count > best_count || (count == best_count && id < best_id) { best_id = id; best_count = count }
			}
		}
		write_i64(output, 16*query, unique_values[best_id])
		write_i64(output, 16*query+8, i64(best_count))
	}
	return i64(16*q)
}
