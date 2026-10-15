module first_n_fibonacci

const min_count = i64(3)
const max_count = i64(79)

fn decimal_length(number_value i64) usize {
	mut remaining := number_value
	mut length := usize(1)
	for remaining >= 10 { remaining /= 10; length++ }
	return length
}

fn required_length(count i64) usize {
	mut bytes := usize(0)
	mut previous := i64(0)
	mut current := i64(1)
	mut index := i64(0)
	for index < count {
		mut value := i64(0)
		if index == 0 { value = 0 } else if index == 1 { value = 1 }
		else { value = previous + current; previous = current; current = value }
		bytes += decimal_length(value) + 1
		index++
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

@[export: 'first_n_fibonacci']
pub fn first_n_fibonacci(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length != 1 { return -1 }
	count := unsafe { values[0] }
	if count < min_count || count > max_count { return -1 }
	required := required_length(count)
	if output_capacity < required { return -2 }
	mut previous := i64(0)
	mut current := i64(1)
	mut index := i64(0)
	mut position := usize(0)
	for index < count {
		mut value := i64(0)
		if index == 0 { value = 0 } else if index == 1 { value = 1 }
		else { value = previous + current; previous = current; current = value }
		position = append_decimal(value, output, position)
		unsafe { output[position] = 0 }
		position++
		index++
	}
	return i64(position)
}
