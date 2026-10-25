module tsvc_s442_indexed_square_accumulate

const max_n = 64
const max_passes = 16
const max_input_length = 386

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'tsvc_s442_indexed_square_accumulate']
pub fn tsvc_s442_indexed_square_accumulate(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 8 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n || input[1] < 1 || input[1] > max_passes { return -1 }
		n := int(input[0])
		passes := int(input[1])
		if int(length) != 2 + 6 * n { return -1 }
		mut a := [max_n]i64{}
		mut b := [max_n]i64{}
		mut c := [max_n]i64{}
		mut d := [max_n]i64{}
		mut e := [max_n]i64{}
		mut selector := [max_n]i64{}
		for i in 0 .. n {
			a[i] = input[2 + i]
			b[i] = input[2 + n + i]
			c[i] = input[2 + 2 * n + i]
			d[i] = input[2 + 3 * n + i]
			e[i] = input[2 + 4 * n + i]
			selector[i] = input[2 + 5 * n + i]
			if a[i] < -2 || a[i] > 2 || b[i] < -2 || b[i] > 2 ||
				c[i] < -2 || c[i] > 2 || d[i] < -2 || d[i] > 2 ||
				e[i] < -2 || e[i] > 2 || selector[i] < 1 || selector[i] > 4 { return -1 }
		}
		if unsafe { output == nil } || capacity < usize(8 * n) { return -2 }
		for round in 0 .. passes {
			for i in 0 .. n {
				mut selected := b[i]
				if selector[i] == 2 { selected = c[i] }
				if selector[i] == 3 { selected = d[i] }
				if selector[i] == 4 { selected = e[i] }
				a[i] += selected * selected
			}
		}
		for i in 0 .. n { store_i64_le(mut output, 8 * i, a[i]) }
		return i64(n)
	}
}
