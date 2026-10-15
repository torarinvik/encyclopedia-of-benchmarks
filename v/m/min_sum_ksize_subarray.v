module min_sum_ksize_subarray

@[export: 'min_sum_ksize_subarray']
pub fn min_sum_ksize_subarray(values &i64, length usize) i64 {
	invalid := i64(-9223372036854775807) - 1
	if length < 2 || length > 100002 { return invalid }
	n_value, k_value := values[0], values[1]
	if n_value < 0 || n_value > 100000 || k_value < 0 || k_value > 100000 { return invalid }
	n, k := int(n_value), int(k_value)
	if length != usize(n + 2) { return invalid }
	for i in 0 .. n {
		if values[i + 2] < -10000 || values[i + 2] > 10000 { return invalid }
	}
	if k > n { return -1 }
	mut window_sum := i64(0)
	for i in 0 .. k { window_sum += values[i + 2] }
	mut minimum_sum := window_sum
	for i in k .. n {
		window_sum += values[i + 2] - values[i - k + 2]
		if window_sum < minimum_sum { minimum_sum = window_sum }
	}
	return minimum_sum
}
