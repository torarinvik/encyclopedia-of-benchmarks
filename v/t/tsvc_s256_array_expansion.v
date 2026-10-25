module tsvc_s256_array_expansion

const max_n = 16
const max_cells = max_n * max_n
const max_input_length = 2 + max_n + 2 * max_cells

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'tsvc_s256_array_expansion']
pub fn tsvc_s256_array_expansion(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 5 || length > max_input_length { return -1 }
	unsafe {
		n_raw, a0 := input[0], input[1]
		if n_raw < 1 || n_raw > max_n || a0 < -1000 || a0 > 1000 { return -1 }
		n := int(n_raw)
		cells := n * n
		if int(length) != 2 + n + 2 * cells { return -1 }
		d_start, b_start, c_start := 2, 2+n, 2+n+cells
		for i in 0 .. n {
			if input[d_start+i] < -1000 || input[d_start+i] > 1000 { return -1 }
		}
		for i in 0 .. cells {
			if input[b_start+i] < -1000 || input[b_start+i] > 1000 ||
				input[c_start+i] < -1_000_000 || input[c_start+i] > 1_000_000 { return -1 }
		}
		output_values := n + cells
		if unsafe { output == nil } || output_capacity < usize(output_values * 8) { return -2 }
		mut a := [max_n]i64{}
		mut c_values := [max_cells]i64{}
		a[0] = a0
		for cell in 0 .. cells { c_values[cell] = input[c_start + cell] }
		for column in 0 .. n {
			for row in 1 .. n {
				a[row] = 1 - a[row - 1]
				cell := row * n + column
				c_values[cell] = a[row] + input[b_start + cell] * input[d_start + row]
			}
		}
		for row in 0 .. n { store_i64_le(mut output, row * 8, a[row]) }
		for cell in 0 .. cells { store_i64_le(mut output, (n + cell) * 8, c_values[cell]) }
		return i64(output_values)
	}
}
