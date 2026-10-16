module p_series

fn decimal_width(value_input u64) int {
	mut value := value_input
	mut width := 1
	for value >= 10 {
		value /= 10
		width++
	}
	return width
}

fn append_decimal(output &u8, position_input int, value_input u64) int {
	mut value := value_input
	mut digits := [20]u8{}
	mut count := 0
	for {
		digits[count] = u8(value % 10)
		count++
		value /= 10
		if value == 0 { break }
	}
	mut position := position_input
	unsafe {
		for count > 0 {
			count--
			output[position] = u8(`0`) + digits[count]
			position++
		}
	}
	return position
}

@[export: 'p_series']
pub fn p_series(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length != 2 { return -1 }
	nth_term := unsafe { values[0] }
	power := unsafe { values[1] }
	if nth_term < -256 || nth_term > 256 || power < 0 || power > 7 { return -1 }
	if nth_term <= 0 { return 0 }
	mut needed := 2
	for term in 2 .. int(nth_term) + 1 {
		mut denominator := u64(1)
		for _ in 0 .. int(power) { denominator *= u64(term) }
		needed += 5 + decimal_width(denominator)
	}
	if output_capacity < usize(needed) { return -2 }
	mut position := 0
	unsafe {
		output[position] = u8(`1`); position++
		output[position] = 10; position++
		for term in 2 .. int(nth_term) + 1 {
			mut denominator := u64(1)
			for _ in 0 .. int(power) { denominator *= u64(term) }
			output[position] = u8(`1`); position++
			output[position] = u8(` `); position++
			output[position] = u8(`/`); position++
			output[position] = u8(` `); position++
			position = append_decimal(output, position, denominator)
			output[position] = 10; position++
		}
	}
	return i64(position)
}
