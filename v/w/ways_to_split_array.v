module ways_to_split_array

const max_length = 100000

// Count positions where the prefix sum is at least the remaining suffix sum.
@[export: 'ways_to_split_array']
pub fn ways_to_split_array(values &i64, length usize) i64 {
	if length < 2 || length > max_length { return -1 }
	mut total := u64(0)
	mut largest_biased_value := u64(0)
	for index in 0 .. length {
		value := u64(unsafe { values[index] })
		biased := value + u64(100000)
		largest_biased_value = if biased > largest_biased_value { biased } else { largest_biased_value }
		total += value
	}
	if largest_biased_value > 200000 { return -1 }
	threshold := i64(total + 1) >> 1
	mut prefix := u64(0)
	mut ways := i64(0)
	for index in 0 .. length - 1 {
		prefix += u64(unsafe { values[index] })
		if i64(prefix) >= threshold { ways++ }
	}
	return ways
}
