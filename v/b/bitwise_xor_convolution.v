module bitwise_xor_convolution

const max_n = 8
const max_size = 1 << max_n
const max_input_length = 1 + 2 * max_size
const modulus = i64(998244353)

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'bitwise_xor_convolution']
pub fn bitwise_xor_convolution(input &i64, length usize, mut output &u8,
	capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_length { return -1 }
		n_value := input[0]
		if n_value < 0 || n_value > max_n { return -1 }
		n := int(n_value)
		size := 1 << n
		if length != usize(1 + 2 * size) { return -1 }
		for index in 0 .. 2 * size {
			value := input[1 + index]
			if value < 0 || value >= modulus { return -1 }
		}
		output_bytes := 8 * size
		if output == nil || capacity < usize(output_bytes) { return -2 }

		mut first := [max_size]i64{}
		mut second := [max_size]i64{}
		for index in 0 .. size {
			first[index] = input[1 + index]
			second[index] = input[1 + size + index]
		}
		mut half := 1
		for half < size {
			for block := 0; block < size; block += 2 * half {
				for offset in 0 .. half {
					left, right := first[block + offset], first[block + half + offset]
					first[block + offset] = (left + right) % modulus
					first[block + half + offset] = (left - right + modulus) % modulus
					left, right = second[block + offset], second[block + half + offset]
					second[block + offset] = (left + right) % modulus
					second[block + half + offset] = (left - right + modulus) % modulus
				}
			}
			half *= 2
		}
		for index in 0 .. size { first[index] = (first[index] * second[index]) % modulus }
		half = 1
		for half < size {
			for block := 0; block < size; block += 2 * half {
				for offset in 0 .. half {
					left, right := first[block + offset], first[block + half + offset]
					first[block + offset] = (left + right) % modulus
					first[block + half + offset] = (left - right + modulus) % modulus
				}
			}
			half *= 2
		}
		mut inverse_size := i64(1)
		for _ in 0 .. n { inverse_size = (inverse_size * ((modulus + 1) / 2)) % modulus }
		for index in 0 .. size {
			store_i64_le(mut output, 8 * index, (first[index] * inverse_size) % modulus)
		}
		return i64(output_bytes)
	}
}
