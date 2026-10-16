const array_count = 3
const max_array_length = 64
const bytes_per_value = 4

fn store_i32_le(mut output &u8, position int, value i64) {
	bits := u32(i32(value))
	for byte in 0 .. bytes_per_value {
		unsafe { output[position + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'sorted_arrays_intersection']
pub fn sorted_arrays_intersection(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < array_count || length > array_count * (max_array_length + 1) { return -1 }
	mut starts := [array_count]int{}
	mut sizes := [array_count]int{}
	mut position := 0
	for array in 0 .. array_count {
		if position >= int(length) || unsafe { input[position] < 0 || input[position] > max_array_length } { return -1 }
		size := int(unsafe { input[position] })
		position++
		if size > int(length) - position { return -1 }
		starts[array] = position
		sizes[array] = size
		for index in 0 .. size {
			value := unsafe { input[position + index] }
			if value < -2147483648 || value > 2147483647 { return -1 }
			if index > 0 && unsafe { input[position + index - 1] >= value } { return -1 }
		}
		position += size
	}
	if position != int(length) { return -1 }
	maximum_result := min(sizes[0], min(sizes[1], sizes[2]))
	if output_capacity < usize(maximum_result * bytes_per_value) || (maximum_result > 0 && unsafe { output == nil }) { return -2 }

	mut cursor := [array_count]int{}
	mut result_count := 0
	for cursor[0] < sizes[0] && cursor[1] < sizes[1] && cursor[2] < sizes[2] {
		first := unsafe { input[starts[0] + cursor[0]] }
		second := unsafe { input[starts[1] + cursor[1]] }
		third := unsafe { input[starts[2] + cursor[2]] }
		if first == second && first == third {
			store_i32_le(mut output, result_count * bytes_per_value, first)
			result_count++
			cursor[0]++; cursor[1]++; cursor[2]++
		} else if first < second {
			cursor[0]++
		} else if second < third {
			cursor[1]++
		} else {
			cursor[2]++
		}
	}
	return i64(result_count)
}
