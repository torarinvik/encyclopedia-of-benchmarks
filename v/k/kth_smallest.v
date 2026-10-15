module kth_smallest

const max_length = 256
const invalid_result = i64(-9223372036854775807 - 1)

fn partition_values(mut values &i32, low_value int, high_value int) int {
	pivot := high_value
	mut i := low_value
	mut j := high_value - 1
	for {
		for unsafe { values[i] < values[pivot] } { i++ }
		for j > 0 && unsafe { values[j] > values[pivot] } { j-- }
		if j == 0 || i >= j { break }
		if unsafe { values[i] == values[j] } {
			i++
			j--
		} else {
			unsafe {
				temporary := values[i]
				values[i] = values[j]
				values[j] = temporary
			}
		}
	}
	unsafe {
		temporary := values[i]
		values[i] = values[pivot]
		values[pivot] = temporary
	}
	return i
}

@[export: 'kth_smallest']
pub fn kth_smallest(input &i64, length usize) i64 {
	if length < 3 || length > max_length + 2 { return invalid_result }
	n_value := unsafe { input[0] }
	k_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_length || k_value < 1 || k_value > n_value || length != usize(n_value + 2) { return invalid_result }
	n := int(n_value)
	mut values := [max_length]i32{}
	for index in 0 .. n {
		value := unsafe { input[index + 2] }
		if value < -2147483648 || value > 2147483647 { return invalid_result }
		values[index] = i32(value)
	}
	mut low := 0
	mut high := n - 1
	mut k := int(k_value)
	for low < high {
		pivot := partition_values(mut values[0], low, high)
		pivot_rank := pivot - low + 1
		if k == pivot_rank { return i64(values[pivot]) }
		if k < pivot_rank {
			high = pivot - 1
		} else {
			low = pivot + 1
			k -= pivot_rank
		}
	}
	return i64(values[low])
}
