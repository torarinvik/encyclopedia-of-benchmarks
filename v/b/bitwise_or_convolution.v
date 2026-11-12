module bitwise_or_convolution

const max_n = 8
const max_size = 1 << max_n
const max_input = 1 + 2 * max_size
const modulus = i64(998244353)

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'bitwise_or_convolution']
pub fn bitwise_or_convolution(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input { return -1 }
		nv := input[0]
		if nv < 0 || nv > max_n { return -1 }
		n := int(nv); size := 1 << n
		if length != usize(1 + 2 * size) { return -1 }
		for i in 0 .. 2 * size { x := input[1 + i]; if x < 0 || x >= modulus { return -1 } }
		bytes := 8 * size
		if output == nil || capacity < usize(bytes) { return -2 }
		mut a := [max_size]i64{}
		mut b := [max_size]i64{}
		for i in 0 .. size { a[i] = input[1+i]; b[i] = input[1+size+i] }
		for bit in 0 .. n {
			bit_mask := 1 << bit
			for mask in 0 .. size { if (mask & bit_mask) != 0 {
				a[mask] = (a[mask] + a[mask ^ bit_mask]) % modulus
				b[mask] = (b[mask] + b[mask ^ bit_mask]) % modulus
			} }
		}
		for i in 0 .. size { a[i] = (a[i] * b[i]) % modulus }
		for bit in 0 .. n {
			bit_mask := 1 << bit
			for mask in 0 .. size { if (mask & bit_mask) != 0 {
				a[mask] -= a[mask ^ bit_mask]
				if a[mask] < 0 { a[mask] += modulus }
			} }
		}
		for i in 0 .. size { store_i64_le(mut output, 8*i, a[i]) }
		return i64(bytes)
	}
}
