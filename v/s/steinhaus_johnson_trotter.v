module steinhaus_johnson_trotter

const max_length = 6

fn emit_row(values []i32, length int, output &u8, mut offset &int) {
	unsafe {
		for index in 0 .. length {
			bits := u32(values[index])
			for byte in 0 .. 4 {
				output[*offset] = u8((bits >> u32(byte * 8)) & 255)
				*offset += 1
			}
		}
	}
}

@[export: 'steinhaus_johnson_trotter']
pub fn steinhaus_johnson_trotter(input &i32, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length == 0 || length > usize(max_length) { return -1 }
		count := int(length)
		mut permutations := 1
		for factor in 2 .. count + 1 { permutations *= factor }
		required := 4 * count * permutations
		if output == nil || output_capacity < usize(required) { return -2 }

		mut values := [max_length]i32{}
		mut inversion := [max_length]int{}
		for index in 0 .. count { values[index] = input[index] }
		mut offset := 0
		emit_row(values[0..count], count, output, mut offset)

		mut index := 1
		for index < count {
			if inversion[index] < index {
				swap_index := if index % 2 == 0 { 0 } else { inversion[index] }
				temporary := values[swap_index]
				values[swap_index] = values[index]
				values[index] = temporary
				emit_row(values[0..count], count, output, mut offset)
				inversion[index]++
				index = 1
			} else {
				inversion[index] = 0
				index++
			}
		}
		return i64(required)
	}
}
