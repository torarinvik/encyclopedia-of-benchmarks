module matrix_multiplication

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'matrix_multiplication']
pub fn matrix_multiplication(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 1 || unsafe { input == nil } { return -2 }
	unsafe {
		dimension := input[0]
		if dimension < 2 || dimension > 8 { return -2 }
		n := int(dimension)
		cells := n * n
		if int(length) != 1 + 2 * cells { return -2 }
		for index in 0 .. 2 * cells {
			if input[1 + index] < -1000 || input[1 + index] > 1000 { return -2 }
		}
		if output == nil || output_capacity < usize(cells * 8) { return -3 }
		for row in 0 .. n {
			for column in 0 .. n {
				mut sum := i64(0)
				for index in 0 .. n {
					sum += input[1 + row*n + index] * input[1 + cells + index*n + column]
				}
				store_i64_le(mut output, (row*n+column)*8, sum)
			}
		}
		return i64(cells)
	}
}
