module majority_elements_floor_half

const max_input_length = 256
const table_size = 512

fn store_i32_le(mut output &u8, offset int, value i32) {
	bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & u32(255)) }
	}
}

@[export: 'majority_elements_floor_half']
pub fn majority_elements_floor_half(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length > max_input_length || (length > 0 && unsafe { input == nil }) { return -1 }
	unsafe {
		mut keys := [table_size]i32{}
		mut counts := [table_size]u16{}
		mut used := [table_size]bool{}
		mut order := [max_input_length]int{}
		mut unique_count := 0
		for index in 0 .. int(length) {
			value := input[index]
			if value < -2147483648 || value > 2147483647 { return -1 }
			mut remainder := value % i64(table_size)
			if remainder < 0 { remainder += i64(table_size) }
			mut slot := int(remainder)
			for used[slot] && i64(keys[slot]) != value { slot = (slot + 1) % table_size }
			if !used[slot] {
				used[slot] = true
				keys[slot] = i32(value)
				counts[slot] = 1
				order[unique_count] = slot
				unique_count++
			} else {
				counts[slot]++
			}
		}

		threshold := u16(int(length) / 2)
		mut result := [max_input_length]i32{}
		mut result_count := 0
		for index in 0 .. unique_count {
			slot := order[index]
			if counts[slot] >= threshold {
				result[result_count] = keys[slot]
				result_count++
			}
		}
		for index := 1; index < result_count; index++ {
			value := result[index]
			mut position := index
			for position > 0 && result[position - 1] > value {
				result[position] = result[position - 1]
				position--
			}
			result[position] = value
		}

		required := usize(result_count * 4)
		if output_capacity < required || (required > 0 && output == nil) { return -2 }
		for index in 0 .. result_count { store_i32_le(mut output, index * 4, result[index]) }
		return i64(result_count)
	}
}
