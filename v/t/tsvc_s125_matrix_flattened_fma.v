module tsvc_s125_matrix_flattened_fma

const max_n = 8
const max_cells = max_n * max_n
const max_input_length = 1 + 3 * max_cells

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'tsvc_s125_matrix_flattened_fma']
pub fn tsvc_s125_matrix_flattened_fma(input &i64, length usize,
	mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n { return -1 }
		n := int(input[0])
		cells := n * n
		if int(length) != 1 + 3 * cells { return -1 }
		mut aa := [max_cells]i64{}
		mut bb := [max_cells]i64{}
		mut cc := [max_cells]i64{}
		mut result := [max_cells]i64{}
		for p in 0 .. cells {
			aa[p] = input[1 + p]
			bb[p] = input[1 + cells + p]
			cc[p] = input[1 + 2 * cells + p]
			if aa[p] < -100 || aa[p] > 100 || bb[p] < -100 || bb[p] > 100 || cc[p] < -100 || cc[p] > 100 { return -1 }
		}
		if unsafe { output == nil } || output_capacity < usize(8 * cells) { return -2 }
		mut k := 0
		for _ in 0 .. n {
			for _ in 0 .. n {
				result[k] = aa[k] + bb[k] * cc[k]
				k++
			}
		}
		for p in 0 .. cells { store_i64_le(mut output, 8 * p, result[p]) }
		return i64(cells)
	}
}
