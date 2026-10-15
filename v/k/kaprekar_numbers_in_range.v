module kaprekar_numbers_in_range

const max_end = i64(100000)

fn is_kaprekar(number i64) bool {
	if number == 0 || number == 1 { return true }
	square := number * number
	mut split := i64(1)
	mut remaining := number
	for remaining > 0 { split *= 10; remaining /= 10 }
	right := square % split
	return right != 0 && square / split + right == number
}

fn decimal_length(number_value i64) usize {
	mut remaining := number_value
	mut length := usize(1)
	for remaining >= 10 { remaining /= 10; length++ }
	return length
}

fn required_length(start i64, ending i64) usize {
	mut bytes := usize(0)
	mut number := start
	for number <= ending {
		if is_kaprekar(number) { bytes += decimal_length(number) + 1 }
		number++
	}
	return bytes
}

fn append_decimal(number_value i64, output &u8, position_value usize) usize {
	mut digits := [20]u8{}
	mut count := usize(0)
	mut number := number_value
	for number > 0 { digits[count] = u8(`0`) + u8(number % 10); count++; number /= 10 }
	if count == 0 { digits[0] = u8(`0`); count = 1 }
	mut position := position_value
	for count > 0 { count--; unsafe { output[position] = digits[count] }; position++ }
	return position
}

@[export: 'kaprekar_numbers_in_range']
pub fn kaprekar_numbers_in_range(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length != 2 { return -1 }
	start := unsafe { values[0] }
	ending := unsafe { values[1] }
	if start < 0 || start > ending || ending > max_end { return -1 }
	required := required_length(start, ending)
	if output_capacity < required { return -2 }
	mut position := usize(0)
	mut number := start
	for number <= ending {
		if is_kaprekar(number) {
			position = append_decimal(number, output, position)
			unsafe { output[position] = 0 }
			position++
		}
		number++
	}
	return i64(position)
}
