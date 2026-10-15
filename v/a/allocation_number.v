module allocation_number

fn append_u64(value_input u64, output &u8, position_value usize) usize {
	mut value := value_input
	mut digits := [20]u8{}
	mut count := 0
	for {
		digits[count] = u8(48 + value % 10)
		count++
		value /= 10
		if value == 0 { break }
	}
	mut position := position_value
	for count > 0 {
		count--
		unsafe { output[position] = digits[count] }
		position++
	}
	return position
}

fn decimal_length(value_input u64) usize {
	mut value := value_input
	mut length := usize(0)
	for {
		length++
		value /= 10
		if value == 0 { break }
	}
	return length
}

@[export: 'allocation_number']
pub fn allocation_number(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length != 2 { return -1 }
	unsafe {
		if values[0] < 1 || values[0] > 1000000 || values[1] < 1 || values[1] > 128 || values[1] > values[0] { return -1 }
		unsafe_total := u64(values[0])
		partitions := u64(values[1])
		block := unsafe_total / partitions
		mut required := usize(0)
		for index := u64(0); index < partitions; index++ {
			start := index * block + 1
			finish := if index + 1 == partitions { unsafe_total } else { (index + 1) * block }
			required += decimal_length(start) + 1 + decimal_length(finish)
			if index + 1 != partitions { required++ }
		}
		if output_capacity < required { return -2 }
		mut position := usize(0)
		for index := u64(0); index < partitions; index++ {
			start := index * block + 1
			finish := if index + 1 == partitions { unsafe_total } else { (index + 1) * block }
			position = append_u64(start, output, position)
			output[position] = u8('-')
			position++
			position = append_u64(finish, output, position)
			if index + 1 != partitions {
				output[position] = u8(',')
				position++
			}
		}
		return i64(position)
	}
}
