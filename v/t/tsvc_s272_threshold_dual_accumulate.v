module tsvc_s272_threshold_dual_accumulate

const max_n = 64
const max_passes = 8
const max_input_length = 3 + 5 * max_n

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'tsvc_s272_threshold_dual_accumulate']
pub fn tsvc_s272_threshold_dual_accumulate(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 8 || length > max_input_length { return -1 }
	unsafe {
		n_raw, passes_raw, threshold := input[0], input[1], input[2]
		if n_raw < 1 || n_raw > max_n || passes_raw < 1 || passes_raw > max_passes || threshold < -2 || threshold > 2 { return -1 }
		n, passes := int(n_raw), int(passes_raw)
		if int(length) != 3 + 5*n { return -1 }
		for i in 3 .. int(length) { if input[i] < -2 || input[i] > 2 { return -1 } }
		if unsafe { output == nil } || output_capacity < usize(16*n) { return -2 }

		a_start, b_start, c_start, d_start, e_start := 3, 3+n, 3+2*n, 3+3*n, 3+4*n
		mut a := [max_n]i64{}
		mut b := [max_n]i64{}
		for i in 0 .. n {
			a[i] = input[a_start+i]
			b[i] = input[b_start+i]
		}
		for _ in 0 .. passes {
			for i in 0 .. n {
				if input[e_start+i] >= threshold {
					a[i] += input[c_start+i] * input[d_start+i]
					b[i] += input[c_start+i] * input[c_start+i]
				}
			}
		}
		for i in 0 .. n {
			store_i64_le(mut output, 8*i, a[i])
			store_i64_le(mut output, 8*(n+i), b[i])
		}
		return i64(2*n)
	}
}
