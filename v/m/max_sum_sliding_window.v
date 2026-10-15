module max_sum_sliding_window

@[export: 'max_sum_sliding_window']
pub fn max_sum_sliding_window(values &i64, length usize) i64 {
	invalid := i64(-9223372036854775807) - 1
	if length < 3 || length > 100002 { return invalid }
	n_value, k_value := values[0], values[1]
	if n_value < 1 || n_value > 100000 || k_value < 1 || k_value > n_value { return invalid }
	n, k := int(n_value), int(k_value)
	if length != usize(n + 2) { return invalid }
	mut current_sum := i64(0)
	for i in 0 .. n {
		value := values[i + 2]
		if value < -1000000000 || value > 1000000000 { return invalid }
		if i < k { current_sum += value }
	}
	mut maximum_sum := current_sum
	for i in 0 .. n - k {
		current_sum = current_sum - values[i + 2] + values[i + k + 2]
		if current_sum > maximum_sum { maximum_sum = current_sum }
	}
	return maximum_sum
}
