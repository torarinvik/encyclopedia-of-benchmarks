module find_all_duplicates_in_array

const max_length = 100_000

fn sift_down(mut values []i32, root_value int, end int) {
	mut root := root_value
	for root*2+1 < end {
		mut child := root*2 + 1
		if child+1 < end && values[child] < values[child + 1] { child++ }
		if values[root] >= values[child] { break }
		values[root], values[child] = values[child], values[root]
		root = child
	}
}

fn heap_sort(mut values []i32) {
	mut start := values.len / 2
	for start > 0 {
		start--
		sift_down(mut values, start, values.len)
	}
	mut ending := values.len
	for ending > 1 {
		ending--
		values[0], values[ending] = values[ending], values[0]
		sift_down(mut values, 0, ending)
	}
}

// Sort a bounded copy and emit sorted duplicate values as little-endian i32s.
@[export: 'find_all_duplicates_in_array']
pub fn find_all_duplicates_in_array(values &i64, length usize, output &u8,
		output_capacity usize) i64 {
	if length > max_length { return -1 }
	if length == 0 { return 0 }

	mut sorted := []i32{len: int(length)}
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < 1 || value > i64(length) { return -1 }
		sorted[index] = i32(value)
	}
	heap_sort(mut sorted)

	mut duplicate_count := 0
	mut index := 0
	for index < sorted.len {
		mut ending := index + 1
		for ending < sorted.len && sorted[ending] == sorted[index] { ending++ }
		frequency := ending - index
		if frequency > 2 { return -1 }
		if frequency == 2 { duplicate_count++ }
		index = ending
	}
	output_bytes := usize(duplicate_count * 4)
	if output_capacity < output_bytes { return -2 }

	mut destination := 0
	index = 0
	for index < sorted.len {
		mut ending := index + 1
		for ending < sorted.len && sorted[ending] == sorted[index] { ending++ }
		if ending - index == 2 {
			value := u32(sorted[index])
			for byte in 0 .. 4 {
				unsafe { output[destination * 4 + byte] = u8((value >> (byte * 8)) & 255) }
			}
			destination++
		}
		index = ending
	}
	return i64(duplicate_count)
}
