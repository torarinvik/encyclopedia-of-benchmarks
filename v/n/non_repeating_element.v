module non_repeating_element

const max_value = i64(1_073_741_823)

@[export: 'non_repeating_element']
pub fn non_repeating_element(values &i64, length usize) i64 {
	if length < 2 || length > 64 || length % 2 != 0 { return -1 }
	mut xor_result := i32(0)
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < 0 || value > max_value { return -1 }
		xor_result ^= i32(value)
	}
	rightmost_set_bit := xor_result & -xor_result
	mut num1 := i32(0)
	mut num2 := i32(0)
	for index in 0 .. length {
		value := i32(unsafe { values[index] })
		if (value & rightmost_set_bit) != 0 { num1 ^= value }
		else { num2 ^= value }
	}
	return (i64(num1) << 32) | i64(u32(num2))
}
