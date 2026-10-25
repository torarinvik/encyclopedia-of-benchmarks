module tsvc_s453_recurrence_weighted_scale

const max_n = 32
const max_input_length = 33

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'tsvc_s453_recurrence_weighted_scale']
pub fn tsvc_s453_recurrence_weighted_scale(input &i64, length usize,
	mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n { return -1 }
		n := int(input[0])
		if int(length) != 1 + n { return -1 }
		mut b := [max_n]i64{}
		mut a := [max_n]i64{}
		for i in 0 .. n {
			b[i] = input[1 + i]
			if b[i] < -100 || b[i] > 100 { return -1 }
		}
		if unsafe { output == nil } || output_capacity < usize(8 * n) { return -2 }
		mut s := i64(0)
		for i in 0 .. n {
			s += 2
			a[i] = s * b[i]
		}
		for i in 0 .. n { store_i64_le(mut output, 8 * i, a[i]) }
		return i64(n)
	}
}
