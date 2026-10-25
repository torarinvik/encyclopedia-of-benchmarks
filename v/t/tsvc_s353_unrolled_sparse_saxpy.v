module tsvc_s353_unrolled_sparse_saxpy

const max_n = 20
const max_input_length = 2 + 3 * max_n

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'tsvc_s353_unrolled_sparse_saxpy']
pub fn tsvc_s353_unrolled_sparse_saxpy(input &i64, length usize,
	mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 17 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 5 || input[0] > max_n || input[0] % 5 != 0 { return -1 }
		n := int(input[0])
		if int(length) != 2 + 3 * n { return -1 }
		alpha := input[1]
		if alpha < -8 || alpha > 8 { return -1 }
		mut a := [max_n]i64{}
		mut b := [max_n]i64{}
		mut indices := [max_n]i64{}
		for i in 0 .. n {
			a[i] = input[2 + i]
			b[i] = input[2 + n + i]
			indices[i] = input[2 + 2 * n + i]
			if a[i] < -1000000 || a[i] > 1000000 || b[i] < -1000000 || b[i] > 1000000 ||
				indices[i] < 0 || indices[i] >= i64(n) { return -1 }
		}
		if unsafe { output == nil } || output_capacity < usize(8 * n) { return -2 }
		for i := 0; i < n; i += 5 {
			a[i] += alpha * b[int(indices[i])]
			a[i + 1] += alpha * b[int(indices[i + 1])]
			a[i + 2] += alpha * b[int(indices[i + 2])]
			a[i + 3] += alpha * b[int(indices[i + 3])]
			a[i + 4] += alpha * b[int(indices[i + 4])]
		}
		for i in 0 .. n { store_i64_le(mut output, 8 * i, a[i]) }
		return i64(n)
	}
}
