module bit_array_count_zero_bits

@[export: 'bit_array_count_zero_bits']
pub fn bit_array_count_zero_bits(values &i64, length usize) i64 {
	if length > 4096 { return -1 }
	mut zero_count := i64(0)
	unsafe {
		for index in 0 .. int(length) {
			value := values[index]
			if value != 0 && value != 1 { return -1 }
			if value == 0 { zero_count++ }
		}
	}
	return zero_count
}
