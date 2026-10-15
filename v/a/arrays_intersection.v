module arrays_intersection

const array_count = 3
const max_array_length = 64
const max_input_length = 195
const max_occurrences = 192
const table_size = 257

fn store_i32_le(mut output &u8, position int, value i64) {
	bits := u32(i32(value))
	for byte in 0 .. 4 {
		unsafe { output[position + byte] = u8(bits >> (byte * 8)) }
	}
}

// Count occurrences across all three arrays and emit first-seen keys with count three.
@[export: 'arrays_intersection']
pub fn arrays_intersection(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < array_count || length > max_input_length { return -1 }
	unsafe {
		mut starts := [array_count]int{}
		mut sizes := [array_count]int{}
		mut position := 0
		for array in 0 .. array_count {
			if position >= int(length) || input[position] < 0 || input[position] > max_array_length { return -1 }
			size := int(input[position])
			position++
			if size > int(length) - position { return -1 }
			starts[array] = position
			sizes[array] = size
			for index in 0 .. size {
				if input[position + index] < -2147483648 || input[position + index] > 2147483647 { return -1 }
			}
			position += size
		}
		if position != int(length) { return -1 }

		mut keys := [table_size]i64{}
		mut counts := [table_size]int{}
		mut occupied := [table_size]bool{}
		mut order := [max_occurrences]int{}
		mut order_length := 0
		for array in 0 .. array_count {
			for index in 0 .. sizes[array] {
				value := input[starts[array] + index]
				remainder := value % i64(table_size)
				if remainder < 0 { remainder += i64(table_size) }
				mut slot := int(remainder)
				for occupied[slot] && keys[slot] != value { slot = (slot + 1) % table_size }
				if !occupied[slot] {
					occupied[slot] = true
					keys[slot] = value
					counts[slot] = 0
					order[order_length] = slot
					order_length++
				}
				counts[slot]++
			}
		}

		mut match_count := 0
		for index in 0 .. order_length {
			if counts[order[index]] == array_count { match_count++ }
		}
		if output_capacity < usize(match_count * 4) || (match_count > 0 && output == nil) { return -2 }
		mut written := 0
		for index in 0 .. order_length {
			slot := order[index]
			if counts[slot] == array_count {
				store_i32_le(mut output, written * 4, keys[slot])
				written++
			}
		}
		return i64(written)
	}
}
