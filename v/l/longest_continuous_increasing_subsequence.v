module longest_continuous_increasing_subsequence

const max_length = 10_000

// Return the longest strictly increasing contiguous run.
@[export: 'longest_continuous_increasing_subsequence']
pub fn longest_continuous_increasing_subsequence(values &i64, length usize) i64 {
	if length > max_length { return -1 }
	for index := 0; index < int(length); index++ {
		value := unsafe { values[index] }
		if value < -1_000_000 || value > 1_000_000 { return -1 }
	}
	if length == 0 { return 0 }

	mut current := i64(1)
	mut best := i64(1)
	for index := 1; index < int(length); index++ {
		if unsafe { values[index] > values[index - 1] } { current++ }
		else { current = 1 }
		if current > best { best = current }
	}
	return best
}
