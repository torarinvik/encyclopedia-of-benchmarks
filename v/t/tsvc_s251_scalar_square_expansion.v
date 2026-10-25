module tsvc_s251_scalar_square_expansion

// Clean-room bounded port of TSVC s251; see package README for provenance.
const max_n = 64
const max_passes = 8
const max_input_length = 2 + 3 * max_n

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'tsvc_s251_scalar_square_expansion']
pub fn tsvc_s251_scalar_square_expansion(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 5 || length > max_input_length { return -1 }
	unsafe {
		n_raw, passes_raw := input[0], input[1]
		if n_raw < 1 || n_raw > max_n || passes_raw < 1 || passes_raw > max_passes { return -1 }
		n, passes := int(n_raw), int(passes_raw)
		if int(length) != 2 + 3*n { return -1 }
		for i in 2 .. int(length) { if input[i] < -2 || input[i] > 2 { return -1 } }
		if unsafe { output == nil } || output_capacity < usize(8*n) { return -2 }

		b_start, c_start, d_start := 2, 2+n, 2+2*n
		mut a := [max_n]i64{}
		for _ in 0 .. passes {
			for i in 0 .. n {
				scalar := input[b_start+i] + input[c_start+i] * input[d_start+i]
				a[i] = scalar * scalar
			}
		}
		for i in 0 .. n { store_i64_le(mut output, 8*i, a[i]) }
		return i64(n)
	}
}
