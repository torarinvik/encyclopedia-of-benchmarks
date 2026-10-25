module tsvc_s122_reverse_strided_gather_add

const max_n = 32
const max_input_length = 67

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'tsvc_s122_reverse_strided_gather_add']
pub fn tsvc_s122_reverse_strided_gather_add(input &i64, length usize,
	mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 5 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n { return -1 }
		n := int(input[0])
		if input[1] < 1 || input[1] > n || input[2] < 1 || input[2] > n { return -1 }
		if int(length) != 3 + 2 * n { return -1 }
		start := int(input[1])
		stride := int(input[2])
		mut a := [max_n]i64{}
		mut b := [max_n]i64{}
		for i in 0 .. n {
			a[i] = input[3 + i]
			b[i] = input[3 + n + i]
			if a[i] < -100 || a[i] > 100 || b[i] < -100 || b[i] > 100 { return -1 }
		}
		if unsafe { output == nil } || output_capacity < usize(8 * n) { return -2 }
		mut j := 1
		mut k := 0
		mut i := start - 1
		for i < n {
			k += j
			a[i] += b[n - k]
			i += stride
		}
		for i in 0 .. n { store_i64_le(mut output, 8 * i, a[i]) }
		return i64(n)
	}
}
