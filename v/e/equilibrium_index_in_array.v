module equilibrium_index_in_array

@[export: 'equilibrium_index_in_array']
pub fn equilibrium_index_in_array(values &i64, length usize) i64 {
	if length < 1 || length > 1025 { return -2 }
	n := unsafe { values[0] }
	if n < 0 || n > 1024 || length != usize(n + 1) { return -2 }
	mut total := i64(0)
	for i in 1 .. length {
		value := unsafe { values[i] }
		if value < -2147483648 || value > 2147483647 { return -2 }
		total += value
	}
	mut left := i64(0)
	for i in 0 .. int(n) {
		value := unsafe { values[i + 1] }
		total -= value
		if left == total { return i64(i) }
		left += value
	}
	return -1
}
