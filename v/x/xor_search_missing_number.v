module xor_search_missing_number

const max_n = 255
const max_input_length = 257

@[export: 'xor_search_missing_number']
pub fn xor_search_missing_number(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_length { return -1 }
		n_value := input[0]
		if n_value < 0 || n_value > max_n || length != usize(n_value + 1) { return -1 }
		mut seen := [256]bool{}
		mut result := n_value
		for i in 0 .. int(n_value) {
			value := input[i + 1]
			if value < 0 || value > n_value || seen[int(value)] { return -1 }
			seen[int(value)] = true
			result ^= i64(i) ^ value
		}
		return result
	}
}
