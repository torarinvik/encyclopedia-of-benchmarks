module max_sum_ksize_subarray

// Maximum sum of a fixed-size window; the final packed value is k.
@[export: 'max_sum_ksize_subarray']
pub fn max_sum_ksize_subarray(values &i64, length usize) i64 {
	if length == 0 || length > 64 { return -1 }
	array_length := length - 1
	k_value := unsafe { values[array_length] }
	if k_value < 0 || k_value > i64(array_length) { return -1 }
	for index in 0 .. array_length {
		value := unsafe { values[index] }
		if value < -1000000 || value > 1000000 { return -1 }
	}
	if k_value == 0 { return 0 }
	k := usize(k_value)
	mut window_sum := i64(0)
	for index in 0 .. k { window_sum += unsafe { values[index] } }
	mut maximum_sum := window_sum
	for index := k; index < array_length; index++ {
		window_sum += unsafe { values[index] - values[index - k] }
		if window_sum > maximum_sum { maximum_sum = window_sum }
	}
	return maximum_sum
}
