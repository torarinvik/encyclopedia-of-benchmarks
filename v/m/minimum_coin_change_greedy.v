const min_target = i64(-4096)
const max_target = i64(4096)
const max_denominations = 32
const max_input_values = 2 + max_denominations
const max_output_bytes = (1 + 4096) * 4

fn write_i32_le(mut output &u8, offset int, value i32) {
	mut bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'minimum_coin_change_greedy']
pub fn minimum_coin_change_greedy(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values { return -1 }
	unsafe {
		target := input[0]
		count_value := input[1]
		if target < min_target || target > max_target || count_value < 0 || count_value > max_denominations { return -1 }
		denomination_count := int(count_value)
		if int(length) != 2 + denomination_count { return -1 }

		mut denominations := [max_denominations]i32{}
		mut previous := i64(0)
		for index in 0 .. denomination_count {
			denomination := input[2 + index]
			if denomination < 1 || denomination > 4096 || denomination <= previous { return -1 }
			denominations[index] = i32(denomination)
			previous = denomination
		}

		mut chosen := [4096]i32{}
		mut chosen_count := 0
		if target > 0 {
			mut remaining := target
			for reverse_index in 0 .. denomination_count {
				index := denomination_count - reverse_index - 1
				denomination := denominations[index]
				for remaining >= i64(denomination) {
					remaining -= i64(denomination)
					chosen[chosen_count] = denomination
					chosen_count++
				}
			}
		}

		needed := (1 + chosen_count) * 4
		if output == nil || capacity < usize(needed) { return -2 }
		write_i32_le(mut output, 0, i32(chosen_count))
		for index in 0 .. chosen_count {
			write_i32_le(mut output, 4 + 4 * index, chosen[index])
		}
		return i64(needed)
	}
}
