module tsvc_s128_strided_coupled_update

const max_n = 16
const max_input_length = 1 + 5 * max_n

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'tsvc_s128_strided_coupled_update']
pub fn tsvc_s128_strided_coupled_update(input &i64, length usize,
	mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 6 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n { return -1 }
		n := int(input[0])
		b_count := 2 * n
		if int(length) != 1 + 5 * n { return -1 }
		mut a := [max_n]i64{}
		mut b := [2 * max_n]i64{}
		mut c := [2 * max_n]i64{}
		mut d := [max_n]i64{}
		for p in 0 .. b_count {
			b[p] = input[1 + p]
			c[p] = input[1 + b_count + p]
			if b[p] < -100 || b[p] > 100 || c[p] < -100 || c[p] > 100 { return -1 }
		}
		for p in 0 .. n {
			d[p] = input[1 + 2 * b_count + p]
			if d[p] < -100 || d[p] > 100 { return -1 }
		}
		output_values := 3 * n
		if unsafe { output == nil } || output_capacity < usize(8 * output_values) { return -2 }
		mut j := i64(-1)
		for i in 0 .. n {
			k := int(j + 1)
			a[i] = b[k] - d[i]
			j = i64(k) + 1
			b[k] = a[i] + c[k]
		}
		for p in 0 .. n { store_i64_le(mut output, 8 * p, a[p]) }
		for p in 0 .. b_count { store_i64_le(mut output, 8 * (n + p), b[p]) }
		return i64(output_values)
	}
}
