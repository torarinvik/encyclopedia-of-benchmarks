module median_of_running_array_byte

const max_count = 64
const max_input_length = 66

fn push_max(mut heap [max_count]i32, mut count int, value i32) {
	mut position := count
	count++
	for position > 0 && heap[(position - 1) / 2] < value { parent := (position - 1) / 2; heap[position] = heap[parent]; position = parent }
	heap[position] = value
}
fn pop_max(mut heap [max_count]i32, mut count int) i32 {
	result := heap[0]
	count--
	value := heap[count]
	if count == 0 { return result }
	mut position := 0
	for 2 * position + 1 < count { mut child := 2 * position + 1; if child + 1 < count && heap[child + 1] > heap[child] { child++ }; if heap[child] <= value { break }; heap[position] = heap[child]; position = child }
	heap[position] = value
	return result
}
fn push_min(mut heap [max_count]i32, mut count int, value i32) {
	mut position := count
	count++
	for position > 0 && heap[(position - 1) / 2] > value { parent := (position - 1) / 2; heap[position] = heap[parent]; position = parent }
	heap[position] = value
}
fn pop_min(mut heap [max_count]i32, mut count int) i32 {
	result := heap[0]
	count--
	value := heap[count]
	if count == 0 { return result }
	mut position := 0
	for 2 * position + 1 < count { mut child := 2 * position + 1; if child + 1 < count && heap[child + 1] < heap[child] { child++ }; if heap[child] >= value { break }; heap[position] = heap[child]; position = child }
	heap[position] = value
	return result
}

@[export: 'median_of_running_array_byte']
pub fn median_of_running_array_byte(input &i32, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	unsafe {
		count_value := input[0]
		if count_value < 1 || count_value > max_count || length != usize(1 + count_value) { return -1 }
		count := int(count_value)
		mut lower := [max_count]i32{}
		mut upper := [max_count]i32{}
		mut medians := [max_count]u8{}
		mut lower_count := 0
		mut upper_count := 0
		for i in 0 .. count {
			sample := input[i + 1]
			if sample < -128 || sample > 127 { return -1 }
			if upper_count > 0 && sample < upper[0] { push_max(mut lower, mut lower_count, sample) }
			else { push_min(mut upper, mut upper_count, sample) }
			if lower_count > upper_count + 1 { push_min(mut upper, mut upper_count, pop_max(mut lower, mut lower_count)) }
			else if upper_count > lower_count + 1 { push_max(mut lower, mut lower_count, pop_min(mut upper, mut upper_count)) }
			mut median := i32(0)
			if lower_count > upper_count { median = lower[0] }
			else if upper_count > lower_count { median = upper[0] }
			else {
				sum := lower[0] + upper[0]
				if sum < 0 { median = -((-sum) / 2) } else { median = sum / 2 }
			}
			medians[i] = u8(median & 255)
		}
		if unsafe { output == nil } || capacity < usize(count) { return -2 }
		for i in 0 .. count { output[i] = medians[i] }
		return i64(count)
	}
}
