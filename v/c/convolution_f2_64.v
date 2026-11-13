module convolution_f2_64

const max_n = 8
const max_m = 8
const max_parseable = 19

fn multiply_in_field(left_value u64, right_value u64) u64 {
	mut shifted := left_value
	mut multiplier := right_value
	mut product := u64(0)
	for _ in 0 .. 64 {
		if (multiplier & 1) != 0 { product ^= shifted }
		carry := shifted >> 63
		shifted <<= 1
		if carry != 0 { shifted ^= u64(0x1b) }
		multiplier >>= 1
	}
	return product
}

@[export: 'convolution_f2_64']
pub fn convolution_f2_64(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_parseable { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n || input[1] < 1 || input[1] > max_m { return -1 }
		n, m := int(input[0]), int(input[1])
		if length != usize(2 + n + m) { return -1 }
		count := n + m - 1
		needed := 8 * count
		if output == nil || output_capacity < usize(needed) { return -2 }
		mut a := []u64{len: max_n}
		mut b := []u64{len: max_m}
		mut product := []u64{len: max_n + max_m - 1}
		for i in 0 .. n { a[i] = u64(input[2 + i]) }
		for j in 0 .. m { b[j] = u64(input[2 + n + j]) }
		for i in 0 .. n {
			for j in 0 .. m { product[i + j] ^= multiply_in_field(a[i], b[j]) }
		}
		for i in 0 .. count {
			bits := product[i]
			for byte in 0 .. 8 {
				output[8 * i + byte] = u8(bits & 255)
				bits >>= 8
			}
		}
		return i64(needed)
	}
}
