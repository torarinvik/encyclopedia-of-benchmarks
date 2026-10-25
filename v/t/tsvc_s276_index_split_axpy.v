module tsvc_s276_index_split_axpy

// Clean-room bounded port of TSVC s276; see package README for provenance.
const max_n = 64
const max_passes = 8
const max_input_length = 2 + 4 * max_n

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'tsvc_s276_index_split_axpy']
pub fn tsvc_s276_index_split_axpy(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 6 || length > max_input_length { return -1 }
	unsafe {
		n_raw, passes_raw := input[0], input[1]
		if n_raw < 1 || n_raw > max_n || passes_raw < 1 || passes_raw > max_passes { return -1 }
		n, passes := int(n_raw), int(passes_raw)
		if int(length) != 2 + 4*n { return -1 }
		for i in 2 .. int(length) { if input[i] < -2 || input[i] > 2 { return -1 } }
		if unsafe { output == nil } || output_capacity < usize(8*n) { return -2 }

		a_start, b_start, c_start, d_start, mid := 2, 2+n, 2+2*n, 2+3*n, n/2
		mut a := [max_n]i64{}
		for i in 0 .. n { a[i] = input[a_start+i] }
		for _ in 0 .. passes {
			for i in 0 .. n {
				coefficient_start := if i+1 < mid { c_start } else { d_start }
				a[i] += input[b_start+i] * input[coefficient_start+i]
			}
		}
		for i in 0 .. n { store_i64_le(mut output, 8*i, a[i]) }
		return i64(n)
	}
}
