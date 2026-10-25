module tsvc_s1221_lag4_add_recurrence

const max_n = 32
const max_input_length = 65

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'tsvc_s1221_lag4_add_recurrence']
pub fn tsvc_s1221_lag4_add_recurrence(input &i64, length usize,
	mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 11 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 5 || input[0] > max_n { return -1 }
		n := int(input[0])
		if int(length) != 1 + 2 * n { return -1 }
		mut a := [max_n]i64{}
		mut b := [max_n]i64{}
		for i in 0 .. n {
			a[i] = input[1 + i]
			b[i] = input[1 + n + i]
			if a[i] < -10 || a[i] > 10 || b[i] < -10 || b[i] > 10 { return -1 }
		}
		output_values := n
		if unsafe { output == nil } || output_capacity < usize(8 * output_values) { return -2 }
		for i in 4 .. n { b[i] = b[i - 4] + a[i] }
		for i in 0 .. n { store_i64_le(mut output, 8 * i, b[i]) }
		return i64(output_values)
	}
}
