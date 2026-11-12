module mul_mod2n_convolution

const max_n = 5
const max_p = 32
const max_input = 66
const max_output = 256
const mod = i64(998244353)

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'mul_mod2n_convolution']
pub fn mul_mod2n_convolution(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n0 := input[0]
		if n0 < 0 || n0 > max_n { return -1 }
		p := 1 << int(n0)
		if length != usize(1 + 2 * p) { return -1 }
		for i in 1 .. int(length) { if input[i] < 0 || input[i] >= mod { return -1 } }
		bytes := 8 * p
		if bytes > max_output { return -1 }
		if output == nil || capacity < usize(bytes) { return -2 }
		mut a := []i64{len: max_p, init: 0}
		mut b := []i64{len: max_p, init: 0}
		mut result := []i64{len: max_p, init: 0}
		for i in 0 .. p { a[i] = input[1 + i]; b[i] = input[1 + p + i] }
		mask := p - 1
		for i in 0 .. p { for j in 0 .. p {
			k := (i * j) & mask
			result[k] = (result[k] + a[i] * b[j]) % mod
		} }
		for i in 0 .. p { store_le(mut output, 8 * i, result[i]) }
		return i64(bytes)
	}
}
