module johnson_trotter_adjacent_gray_code

const max_n = 3
const max_output_bytes = 144

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@[export: 'johnson_trotter_adjacent_gray_code']
pub fn johnson_trotter_adjacent_gray_code(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length != 1 || input[0] < 1 || input[0] > max_n { return -1 }
		n := int(input[0])
		mut permutation_count := 1
		for value in 2 .. (n + 1) { permutation_count *= value }
		output_bytes := 8 * n * permutation_count
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut permutation := [max_n]i64{init: 0}
		mut direction := [max_n + 1]i64{init: 0}
		for index in 0 .. n { permutation[index] = i64(index + 1); direction[index + 1] = -1 }
		mut staged := [max_output_bytes]u8{init: 0}
		mut rows := 0
		for {
			for index in 0 .. n { store_i64_le(mut staged[..], 8 * (rows * n + index), permutation[index]) }
			rows++
			mut largest_mobile := i64(0)
			mut mobile_position := -1
			for position in 0 .. n {
				value := permutation[position]
				neighbor := position + int(direction[value])
				if neighbor >= 0 && neighbor < n && value > permutation[neighbor] && value > largest_mobile {
					largest_mobile, mobile_position = value, position
				}
			}
			if mobile_position < 0 { break }
			neighbor := mobile_position + int(direction[largest_mobile])
			permutation[mobile_position], permutation[neighbor] = permutation[neighbor], permutation[mobile_position]
			for value in (int(largest_mobile) + 1) .. (n + 1) { direction[value] = -direction[value] }
		}
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
