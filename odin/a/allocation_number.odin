package allocation_number

import "core:c"

append_u64 :: proc "contextless" (value_input: u64, output: [^]u8, capacity: int, position: ^int) -> bool {
	value := value_input
	digits: [20]u8
	count := 0
	for {
		digits[count] = u8('0' + value % 10)
		count += 1
		value /= 10
		if value == 0 do break
	}
	if count > capacity - position^ do return false
	for count > 0 {
		count -= 1
		output[position^] = digits[count]
		position^ += 1
	}
	return true
}

@(export)
allocation_number :: proc "c" (values: [^]i64, length: c.size_t,
								output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length != 2 do return -1
	if values[0] < 1 || values[0] > 1000000 || values[1] < 1 || values[1] > 128 || values[1] > values[0] do return -1
	total := u64(values[0])
	partitions := u64(values[1])
	block := total / partitions
	position := 0
	for index := u64(0); index < partitions; index += 1 {
		start := index * block + 1
		finish := if index + 1 == partitions do total else (index + 1) * block
		if !append_u64(start, output, int(output_capacity), &position) do return -2
		if position >= int(output_capacity) do return -2
		output[position] = u8('-')
		position += 1
		if !append_u64(finish, output, int(output_capacity), &position) do return -2
		if index + 1 != partitions {
			if position >= int(output_capacity) do return -2
			output[position] = u8(',')
			position += 1
		}
	}
	return i64(position)
}
