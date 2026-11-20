module binary_search_maximum_average_segment

const max_n = 32
const max_input = 35
const invalid_result = i64(-1_000_001)

fn feasible(input &i64, n int, minimum_length int, threshold i64) bool {
	mut prefix := [33]i64{}
	for index in 0 .. n {
		prefix[index + 1] = prefix[index] + 1000 * input[index + 2] - threshold
	}
	mut minimum_prefix := i64(9_223_372_036_854_775_807)
	for end in minimum_length .. n + 1 {
		eligible_start := end - minimum_length
		if prefix[eligible_start] < minimum_prefix { minimum_prefix = prefix[eligible_start] }
		if prefix[end] >= minimum_prefix { return true }
	}
	return false
}

@[export: 'binary_search_maximum_average_segment']
pub fn binary_search_maximum_average_segment(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input { return invalid_result }
	n_value, minimum_value := input[0], input[1]
	if n_value < 1 || n_value > max_n || minimum_value < 1 || minimum_value > n_value { return invalid_result }
	n := int(n_value)
	if length != usize(n + 2) { return invalid_result }
	for index in 0 .. n {
		if input[index + 2] < -1000 || input[index + 2] > 1000 { return invalid_result }
	}

	mut low := i64(-1_000_000)
	mut high := i64(1_000_001)
	for high - low > 1 {
		middle := low + (high - low) / 2
		if feasible(input, n, int(minimum_value), middle) { low = middle } else { high = middle }
	}
	return low
}
