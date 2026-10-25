module tsvc_s114_transposed_lower_triangle_update

const max_n = 16
const max_input_length = 1 + 2 * max_n * max_n
const max_value = i64(1000000)

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'tsvc_s114_transposed_lower_triangle_update']
pub fn tsvc_s114_transposed_lower_triangle_update(input &i64, length usize,
	mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 9 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 2 || input[0] > max_n { return -1 }
		n := int(input[0]); cells := n * n
		if int(length) != 1 + 2 * cells { return -1 }
		mut a := [max_n * max_n]i64{}
		mut b := [max_n * max_n]i64{}
		for i in 0 .. cells {
			a[i] = input[1 + i]; b[i] = input[1 + cells + i]
			if a[i] < -max_value || a[i] > max_value || b[i] < -max_value || b[i] > max_value { return -1 }
		}
		if output == nil || output_capacity < usize(8 * cells) { return -2 }
		for i in 0 .. n { for j in 0 .. i { a[i * n + j] = a[j * n + i] + b[i * n + j] } }
		for i in 0 .. cells { store_i64_le(mut output, 8 * i, a[i]) }
		return i64(cells)
	}
}
