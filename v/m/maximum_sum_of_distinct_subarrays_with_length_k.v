module maximum_sum_of_distinct_subarrays_with_length_k

@[export: 'maximum_sum_of_distinct_subarrays_with_length_k']
pub fn maximum_sum_of_distinct_subarrays_with_length_k(values &i64, length usize) i64 {
	invalid := i64(-9223372036854775807) - 1
	if length < 3 || length > 8194 { return invalid }
	n_value, k_value := values[0], values[1]
	if n_value < 1 || n_value > 8192 || k_value < 1 || k_value > n_value { return invalid }
	n, k := int(n_value), int(k_value)
	if length != usize(n + 2) { return invalid }
	mut keys := [16384]i32{init: 0}
	mut last_plus_one := [16384]i32{init: 0}
	mut current_sum := i64(0)
	mut maximum_sum := i64(0)
	mut distinct_start := 0
	for i in 0 .. n {
		input := values[i + 2]
		if input < -2147483648 || input > 2147483647 { return invalid }
		value := i32(input)
		if i < k { current_sum += value }
		else {
			current_sum -= values[i - k + 2]
			current_sum += value
		}
		slot := int((input + 2147483648) % 16384)
		for last_plus_one[slot] != 0 && keys[slot] != value { slot = (slot + 1) & 16383 }
		if last_plus_one[slot] != 0 {
			previous := int(last_plus_one[slot] - 1)
			if previous >= distinct_start { distinct_start = previous + 1 }
		} else { keys[slot] = value }
		last_plus_one[slot] = i32(i + 1)
		if i + 1 >= k {
			start := i + 1 - k
			if start >= distinct_start && current_sum > maximum_sum { maximum_sum = current_sum }
		}
	}
	return maximum_sum
}
