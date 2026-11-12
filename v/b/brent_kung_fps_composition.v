module brent_kung_fps_composition

const modulus = i64(998244353)
const max_n = 32
const max_input = usize(66)

fn multiply_truncated(left [32]i64, right [32]i64, n int) [32]i64 {
	mut product := [32]i64{}
	for i in 0 .. n {
		for j in 0 .. n - i {
			product[i + j] = (product[i + j] + left[i] * right[j]) % modulus
		}
	}
	return product
}

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'brent_kung_fps_composition']
pub fn brent_kung_fps_composition(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n_value := input[0]
		if n_value < 1 || n_value > max_n { return -1 }
		n := int(n_value)
		if length != usize(1 + 2 * n) { return -1 }
		for i in 0 .. 2 * n {
			if input[i + 1] < 0 || input[i + 1] >= modulus { return -1 }
		}
		if input[1 + n] != 0 { return -1 }
		bytes := 8 * n
		if output == nil || capacity < usize(bytes) { return -2 }

		mut block_size := 1
		for block_size * block_size < n { block_size++ }
		block_count := (n + block_size - 1) / block_size
		mut powers := [7][32]i64{}
		mut blocks := [6][32]i64{}
		mut inner := [32]i64{}
		for degree in 0 .. n { inner[degree] = input[1 + n + degree] }
		powers[0][0] = 1
		power_end := block_size + 1
		for exponent in 1 .. power_end {
			powers[exponent] = multiply_truncated(powers[exponent - 1], inner, n)
		}
		for block in 0 .. block_count {
			for offset in 0 .. block_size {
				coefficient_index := block * block_size + offset
				if coefficient_index >= n { break }
				coefficient := input[1 + coefficient_index]
				for degree in 0 .. n {
					blocks[block][degree] =
						(blocks[block][degree] + coefficient * powers[offset][degree]) % modulus
				}
			}
		}
		mut composed := blocks[block_count - 1]
		mut block := block_count - 1
		for block > 0 {
			composed = multiply_truncated(composed, powers[block_size], n)
			for degree in 0 .. n {
				composed[degree] = (composed[degree] + blocks[block - 1][degree]) % modulus
			}
			block--
		}
		for degree in 0 .. n { store_le(mut output, 8 * degree, composed[degree]) }
		return i64(bytes)
	}
}
