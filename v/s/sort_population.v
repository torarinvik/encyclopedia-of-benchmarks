module sort_population

fn write_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'sort_population']
pub fn sort_population(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 3 || length > 129 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 64 { return -1 }
		count := int(input[0])
		if int(length) != 1 + 2 * count { return -1 }
		mut costs := []i64{len: 64, init: 0}
		mut identifiers := []i64{len: 64, init: 0}
		mut seen := []bool{len: 64, init: false}
		for index := 0; index < count; index++ {
			cost := input[1 + 2 * index]
			identifier := input[2 + 2 * index]
			if cost < -1000000 || cost > 1000000 || identifier < 0 || identifier >= i64(count) { return -1 }
			if seen[int(identifier)] { return -1 }
			seen[int(identifier)] = true
			costs[index] = cost
			identifiers[index] = identifier
		}
		for index := 1; index < count; index++ {
			key_cost := costs[index]
			key_identifier := identifiers[index]
			mut position := index
			for position > 0 && costs[position - 1] > key_cost {
				costs[position] = costs[position - 1]
				identifiers[position] = identifiers[position - 1]
				position--
			}
			costs[position] = key_cost
			identifiers[position] = key_identifier
		}
		for index := 1; index < count; index++ {
			if costs[index - 1] == costs[index] { return -1 }
		}
		output_length := count * 16
		if output == nil || capacity < usize(output_length) { return -2 }
		for index := 0; index < count; index++ {
			write_i64_le(mut output, index * 16, costs[index])
			write_i64_le(mut output, index * 16 + 8, identifiers[index])
		}
		return i64(output_length)
	}
}
