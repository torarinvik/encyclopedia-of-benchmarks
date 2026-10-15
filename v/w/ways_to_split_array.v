module ways_to_split_array

const max_length = 100000

// Count positions where the prefix sum is at least the remaining suffix sum.
@[export: 'ways_to_split_array']
pub fn ways_to_split_array(values &i64, length usize) i64 {
	if length < 2 || length > max_length { return -1 }
	mut total_sum := i64(0)
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < -i64(100000) || value > i64(100000) { return -1 }
		total_sum += value
	}
	mut prefix_sum := i64(0)
	mut ways := i64(0)
	for index in 0 .. length - 1 {
		prefix_sum += unsafe { values[index] }
		if prefix_sum >= total_sum - prefix_sum { ways++ }
	}
	return ways
}
