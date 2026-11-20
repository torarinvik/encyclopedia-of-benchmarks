module powerful_numbers_square_cube_enumeration

const max_input_words = 2
const max_limit = i64(100)

fn is_squarefree(value i64) bool {
	mut divisor := i64(2)
	for divisor <= value / divisor {
		if value % (divisor * divisor) == 0 { return false }
		divisor++
	}
	return true
}

fn store_i64_le(output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits >> (8 * byte)) }
	}
}

@[export: 'powerful_numbers_square_cube_enumeration']
pub fn powerful_numbers_square_cube_enumeration(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > usize(max_input_words) || length != 1 { return -1 }
	limit := unsafe { input[0] }
	if limit < 1 || limit > max_limit { return -1 }

	mut values := [14]i64{}
	mut count := 0
	mut b := i64(1)
	for b * b * b <= limit {
		if is_squarefree(b) {
			cube := b * b * b
			mut a := i64(1)
			for a * a * cube <= limit {
				values[count] = a * a * cube
				count++
				a++
			}
		}
		b++
	}
	for index in 1 .. count {
		value := values[index]
		mut position := index
		for position > 0 && values[position - 1] > value {
			values[position] = values[position - 1]
			position--
		}
		values[position] = value
	}

	output_bytes := (count + 1) * 8
	if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
	unsafe {
		store_i64_le(output, 0, i64(count))
		for index in 0 .. count {
			store_i64_le(output, (index + 1) * 8, values[index])
		}
	}
	return i64(output_bytes)
}
