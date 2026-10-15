module harshad_numbers_in_base

const max_limit = i64(10000)

fn digit_sum(number_value i64, base i64) i64 {
	mut remaining := number_value
	mut sum := i64(0)
	for remaining > 0 {
		sum += remaining % base
		remaining /= base
	}
	return sum
}

fn base_length(number_value i64, base i64) usize {
	mut remaining := number_value
	mut length := usize(0)
	for remaining > 0 {
		length++
		remaining /= base
	}
	return length
}

fn required_length(limit i64, base i64) usize {
	mut length := usize(0)
	mut number := i64(1)
	for number < limit {
		if number % digit_sum(number, base) == 0 {
			length += base_length(number, base) + 1
		}
		number++
	}
	return length
}

fn digit_byte(digit i64) u8 {
	if digit < 10 { return u8(`0`) + u8(digit) }
	return u8(`A`) + u8(digit - 10)
}

fn append_base(number_value i64, base i64, output &u8, position_value usize) usize {
	mut digits := [64]u8{}
	mut count := usize(0)
	mut remaining := number_value
	for remaining > 0 {
		digits[count] = digit_byte(remaining % base)
		count++
		remaining /= base
	}
	mut position := position_value
	for count > 0 {
		count--
		unsafe { output[position] = digits[count] }
		position++
	}
	return position
}

@[export: 'harshad_numbers_in_base']
pub fn harshad_numbers_in_base(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length != 2 { return -1 }
	limit := unsafe { values[0] }
	base := unsafe { values[1] }
	if limit > max_limit || base < 2 || base > 36 { return -1 }
	required := required_length(limit, base)
	if output_capacity < required { return -2 }
	mut position := usize(0)
	mut number := i64(1)
	for number < limit {
		if number % digit_sum(number, base) == 0 {
			position = append_base(number, base, output, position)
			unsafe { output[position] = 0 }
			position++
		}
		number++
	}
	return i64(position)
}
