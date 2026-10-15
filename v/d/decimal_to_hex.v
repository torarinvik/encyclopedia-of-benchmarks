module decimal_to_hex

@[export: 'decimal_to_hex']
pub fn decimal_to_hex(value_input i64, mut output &u8, capacity usize) i64 {
	if value_input < 0 || value_input > 9_007_199_254_740_991 { return -1 }
	mut value := value_input
	mut width := 1
	mut n := value
	for n >= 16 { width++; n /= 16 }
	if unsafe { output == nil } || capacity < usize(width) { return -2 }
	mut position := width
	unsafe {
		for position > 0 {
			position--
			digit := value % 16
			if digit < 10 { output[position] = u8('0' + digit) }
			else { output[position] = u8('A' + digit - 10) }
			value /= 16
		}
	}
	return i64(width)
}
