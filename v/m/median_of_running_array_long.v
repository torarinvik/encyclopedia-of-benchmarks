module median_of_running_array_long

const max_count = 64
const max_input_length = 66
const min_sample = i64(-4611686018427387904)
const max_sample = i64(4611686018427387903)

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset+byte] = u8((bits >> u64(8*byte)) & 255) } }
}
fn push_max(mut heap [64]i64, mut count int, value i64) {
	mut position := count; count++
	for position > 0 && heap[(position-1)/2] < value { parent := (position-1)/2; heap[position] = heap[parent]; position = parent }
	heap[position] = value
}
fn pop_max(mut heap [64]i64, mut count int) i64 {
	result := heap[0]; count--; value := heap[count]
	if count == 0 { return result }
	mut position := 0
	for 2*position+1 < count { mut child := 2*position+1; if child+1 < count && heap[child+1] > heap[child] { child++ }; if heap[child] <= value { break }; heap[position] = heap[child]; position = child }
	heap[position] = value; return result
}
fn push_min(mut heap [64]i64, mut count int, value i64) {
	mut position := count; count++
	for position > 0 && heap[(position-1)/2] > value { parent := (position-1)/2; heap[position] = heap[parent]; position = parent }
	heap[position] = value
}
fn pop_min(mut heap [64]i64, mut count int) i64 {
	result := heap[0]; count--; value := heap[count]
	if count == 0 { return result }
	mut position := 0
	for 2*position+1 < count { mut child := 2*position+1; if child+1 < count && heap[child+1] < heap[child] { child++ }; if heap[child] >= value { break }; heap[position] = heap[child]; position = child }
	heap[position] = value; return result
}

@[export: 'median_of_running_array_long']
pub fn median_of_running_array_long(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	unsafe {
		count_value := input[0]
		if count_value < 1 || count_value > max_count || length != usize(1+count_value) { return -1 }
		count := int(count_value)
		mut lower := [64]i64{}
		mut upper := [64]i64{}
		mut medians := [64]i64{}
		mut lower_count := 0; mut upper_count := 0
		for i in 0 .. count {
			sample := input[i+1]
			if sample < min_sample || sample > max_sample { return -1 }
			if upper_count > 0 && sample < upper[0] { push_max(mut lower, mut lower_count, sample) }
			else { push_min(mut upper, mut upper_count, sample) }
			if lower_count > upper_count+1 { push_min(mut upper, mut upper_count, pop_max(mut lower, mut lower_count)) }
			else if upper_count > lower_count+1 { push_max(mut lower, mut lower_count, pop_min(mut upper, mut upper_count)) }
			if lower_count > upper_count { medians[i] = lower[0] }
			else if upper_count > lower_count { medians[i] = upper[0] }
			else { medians[i] = (lower[0] + upper[0]) / 2 }
		}
		output_bytes := count * 8
		if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
		for i in 0 .. count { store_i64_le(mut output, 8*i, medians[i]) }
		return i64(output_bytes)
	}
}
