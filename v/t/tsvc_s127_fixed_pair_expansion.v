module tsvc_s127_fixed_pair_expansion

const max_n = 32
const max_input_length = 1 + 4 * max_n

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'tsvc_s127_fixed_pair_expansion']
pub fn tsvc_s127_fixed_pair_expansion(input &i64, length usize,
	mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 5 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n { return -1 }
		n := int(input[0])
		if int(length) != 1 + 4 * n { return -1 }
		mut b := [max_n]i64{}
		mut c := [max_n]i64{}
		mut d := [max_n]i64{}
		mut e := [max_n]i64{}
		mut a := [2 * max_n]i64{}
		for i in 0 .. n {
			b[i] = input[1 + i]
			c[i] = input[1 + n + i]
			d[i] = input[1 + 2 * n + i]
			e[i] = input[1 + 3 * n + i]
			if b[i] < -100 || b[i] > 100 || c[i] < -100 || c[i] > 100 ||
				d[i] < -100 || d[i] > 100 || e[i] < -100 || e[i] > 100 { return -1 }
		}
		output_values := 2 * n
		if unsafe { output == nil } || output_capacity < usize(8 * output_values) { return -2 }
		mut j := i64(-1)
		for i in 0 .. n {
			j++
			a[int(j)] = b[i] + c[i] * d[i]
			j++
			a[int(j)] = b[i] + d[i] * e[i]
		}
		for i in 0 .. output_values { store_i64_le(mut output, 8 * i, a[i]) }
		return i64(output_values)
	}
}
