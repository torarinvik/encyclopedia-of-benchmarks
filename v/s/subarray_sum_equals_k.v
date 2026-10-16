module subarray_sum_equals_k

const invalid_result = i64(-9223372036854775807 - 1)
const max_items = 512
const table_size = 2048

fn slot_for(value i64) int {
	magnitude := if value < 0 { -value } else { value }
	return int(magnitude % 2048)
}

@[export: 'subarray_sum_equals_k']
pub fn subarray_sum_equals_k(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 514 { return invalid_result }
	count_value := unsafe { input[0] }
	target := unsafe { input[1] }
	if count_value < 0 || count_value > i64(max_items) || target < -2147483648 || target > 2147483647 {
		return invalid_result
	}
	count := int(count_value)
	if length != usize(count + 2) { return invalid_result }
	for index in 0 .. count {
		value := unsafe { input[index + 2] }
		if value < -2147483648 || value > 2147483647 { return invalid_result }
	}

	mut keys := [table_size]i64{}
	mut frequencies := [table_size]i64{}
	frequencies[0] = 1
	mut prefix_sum := i64(0)
	mut result := i64(0)
	for index in 0 .. count {
		prefix_sum += unsafe { input[index + 2] }
		required := prefix_sum - target
		mut slot := slot_for(required)
		for frequencies[slot] != 0 && keys[slot] != required { slot = (slot + 1) % table_size }
		result += frequencies[slot]

		slot = slot_for(prefix_sum)
		for frequencies[slot] != 0 && keys[slot] != prefix_sum { slot = (slot + 1) % table_size }
		if frequencies[slot] == 0 { keys[slot] = prefix_sum }
		frequencies[slot]++
	}
	return result
}
