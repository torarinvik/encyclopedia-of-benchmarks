module tsvc_s252_adjacent_product_pair_sum

const max_n = 64
const max_input_length = 129

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'tsvc_s252_adjacent_product_pair_sum']
pub fn tsvc_s252_adjacent_product_pair_sum(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n { return -1 }
		n := int(input[0])
		if int(length) != 1 + 2 * n { return -1 }
		mut b := [max_n]i64{}
		mut c := [max_n]i64{}
		for i in 0 .. n {
			b[i] = input[1 + i]
			c[i] = input[1 + n + i]
			if b[i] < -2 || b[i] > 2 || c[i] < -2 || c[i] > 2 { return -1 }
		}
		if unsafe { output == nil } || capacity < usize(8 * n) { return -2 }
		mut previous_product := i64(0)
		for i in 0 .. n {
			product := b[i] * c[i]
			store_i64_le(mut output, 8 * i, product + previous_product)
			previous_product = product
		}
		return i64(n)
	}
}
