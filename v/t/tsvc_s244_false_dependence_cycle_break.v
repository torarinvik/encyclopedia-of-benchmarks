module tsvc_s244_false_dependence_cycle_break

const max_n = 32
const max_input_length = 129

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'tsvc_s244_false_dependence_cycle_break']
pub fn tsvc_s244_false_dependence_cycle_break(input &i64, length usize,
	mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 9 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 2 || input[0] > max_n { return -1 }
		n := int(input[0])
		if int(length) != 1 + 4 * n { return -1 }
		mut a := [max_n]i64{}
		mut b := [max_n]i64{}
		mut c := [max_n]i64{}
		mut d := [max_n]i64{}
		mut trace := [max_n - 1]i64{}
		for i in 0 .. n {
			a[i] = input[1 + i]
			b[i] = input[1 + n + i]
			c[i] = input[1 + 2 * n + i]
			d[i] = input[1 + 3 * n + i]
			if a[i] < -2 || a[i] > 2 || b[i] < -2 || b[i] > 2 ||
				c[i] < -2 || c[i] > 2 || d[i] < -2 || d[i] > 2 { return -1 }
		}
		output_values := 3 * n - 1
		if unsafe { output == nil } || output_capacity < usize(8 * output_values) { return -2 }
		for i in 0 .. n - 1 {
			a[i] = b[i] + c[i] * d[i]
			b[i] = c[i] + b[i]
			a[i + 1] = b[i] + a[i + 1] * d[i]
			trace[i] = a[i + 1]
		}
		mut offset := 0
		for i in 0 .. n {
			store_i64_le(mut output, 8 * offset, a[i])
			offset++
		}
		for i in 0 .. n {
			store_i64_le(mut output, 8 * offset, b[i])
			offset++
		}
		for i in 0 .. n - 1 {
			store_i64_le(mut output, 8 * offset, trace[i])
			offset++
		}
		return i64(output_values)
	}
}
