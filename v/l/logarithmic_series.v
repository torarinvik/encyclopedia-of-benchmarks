module logarithmic_series

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

fn has_negative_sign(delta i64, term int) bool {
	return (delta < 0 && term % 2 == 1) || (delta >= 0 && term % 2 == 0)
}

@[export: 'logarithmic_series']
pub fn logarithmic_series(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length != 2 { return -1 }
	x_value := unsafe { values[0] }
	n_terms := unsafe { values[1] }
	if x_value < -10 || x_value > 10 || n_terms < -64 || n_terms > 256 { return -1 }
	if n_terms <= 0 { return 0 }
	delta := x_value - 1
	base := u64(if delta < 0 { -delta } else { delta })
	mut needed := 0
	for term in 1 .. int(n_terms) + 1 {
		prefix := if has_negative_sign(delta, term) { 2 } else { 1 }
		needed += prefix + decimal_width(base) + 2 * decimal_width(u64(term)) + 4
	}
	if output_capacity < usize(needed) { return -2 }
	mut position := 0
	unsafe {
		for term in 1 .. int(n_terms) + 1 {
			if has_negative_sign(delta, term) { output[position] = u8(`-`); position++ }
			output[position] = u8(`(`); position++
			position = append_decimal(output, position, base)
			output[position] = u8(`^`); position++
			position = append_decimal(output, position, u64(term))
			output[position] = u8(`)`); position++
			output[position] = u8(`/`); position++
			position = append_decimal(output, position, u64(term))
			output[position] = 10; position++
		}
	}
	return i64(position)
}
