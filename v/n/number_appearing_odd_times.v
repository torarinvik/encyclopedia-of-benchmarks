module number_appearing_odd_times

const max_length = 4096
const invalid_result = i64(-2_147_483_649)

// XOR-fold an int32 array to find its unique odd-frequency value.
@[export: 'number_appearing_odd_times']
pub fn number_appearing_odd_times(values &i64, length usize) i64 {
	if length == 0 || length > max_length { return invalid_result }
	mut result := i32(0)
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < -2_147_483_648 || value > 2_147_483_647 { return invalid_result }
		result = result ^ i32(value)
	}
	return i64(result)
}
