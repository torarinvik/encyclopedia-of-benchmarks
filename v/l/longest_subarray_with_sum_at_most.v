module longest_subarray_with_sum_at_most
const invalid_result = i64(-1)
const max_input_length = 259
const max_domain_value = i64(2147483647)
@[export: 'longest_subarray_with_sum_at_most']
pub fn longest_subarray_with_sum_at_most(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return invalid_result }
	unsafe {
		target, raw_count := input[0], input[1]
		if target < 0 || target > max_domain_value || raw_count < 0 || raw_count > 256 { return invalid_result }
		count := int(raw_count)
		if length != usize(count + 2) { return invalid_result }
		for index in 0 .. count {
			value := input[index + 2]
			if value < 0 || value > max_domain_value { return invalid_result }
		}
		mut left, mut best_length := 0, 0
		mut window_sum := i64(0)
		for right in 0 .. count {
			window_sum += input[right + 2]
			for window_sum > target && left <= right {
				window_sum -= input[left + 2]
				left++
			}
			current_length := if left <= right { right - left + 1 } else { 0 }
			if current_length > best_length { best_length = current_length }
		}
		return i64(best_length)
	}
}
