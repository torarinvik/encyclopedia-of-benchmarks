module missing_number_in_range

const max_values = 1024

fn encode_i32(value i64) u64 {
	if value < 0 { return u64(value + 4294967296) }
	return u64(value)
}

@[export: 'missing_number_in_range']
pub fn missing_number_in_range(values &i64, length usize) i64 {
	if length < 2 || length > max_values { return -2147483649 }
	mut low := unsafe { values[0] }
	mut high := low
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < -2147483648 || value > 2147483647 { return -2147483649 }
		if value < low { low = value }
		if value > high { high = value }
	}
	if high - low != i64(length) { return -2147483649 }
	mut seen := [max_values + 1]bool{}
	mut actual := u64(0)
	for index in 0 .. length {
		value := unsafe { values[index] }
		slot := int(value - low)
		if seen[slot] { return -2147483649 }
		seen[slot] = true
		actual = actual ^ encode_i32(value)
	}
	mut expected := u64(0)
	mut value := low
	for value <= high {
		expected = expected ^ encode_i32(value)
		value++
	}
	result := expected ^ actual
	if result <= 2147483647 { return i64(result) }
	return i64(result) - 4294967296
}
