module proper_fractions

fn gcd(left_input i64, right_input i64) i64 {
	mut left := left_input
	mut right := right_input
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn decimal_width(value_input u64) int {
	mut value := value_input
	mut width := 1
	for value >= 10 { value /= 10; width++ }
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

@[export: 'proper_fractions']
pub fn proper_fractions(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length != 1 { return -1 }
	denominator := unsafe { values[0] }
	if denominator < 0 || denominator > 256 { return -1 }
	if denominator <= 1 { return 0 }
	mut needed := 0
	for numerator in 1 .. int(denominator) {
		if gcd(i64(numerator), denominator) == 1 {
			needed += decimal_width(u64(numerator)) + decimal_width(u64(denominator)) + 2
		}
	}
	if output_capacity < usize(needed) { return -2 }
	mut position := 0
	unsafe {
		for numerator in 1 .. int(denominator) {
			if gcd(i64(numerator), denominator) != 1 { continue }
			position = append_decimal(output, position, u64(numerator))
			output[position] = u8(`/`); position++
			position = append_decimal(output, position, u64(denominator))
			output[position] = 10; position++
		}
	}
	return i64(position)
}
