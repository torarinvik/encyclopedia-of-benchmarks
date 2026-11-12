package bitwise_xor_convolution

import "core:c"

MAX_N :: 8
MAX_SIZE :: 1 << MAX_N
MAX_INPUT_LENGTH :: 1 + 2 * MAX_SIZE
MODULUS :: i64(998244353)

xor_walsh_transform :: proc(values: [^]i64, size: int) {
	for half := 1; half < size; half *= 2 {
		for block := 0; block < size; block += 2*half {
			for offset := 0; offset < half; offset += 1 {
				left, right := values[block+offset], values[block+half+offset]
				values[block+offset] = (left + right) % MODULUS
				values[block+half+offset] = (left - right + MODULUS) % MODULUS
			}
		}
	}
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
	bits := u64(value)
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
bitwise_xor_convolution :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) { return -1 }
	n_value := input[0]
	if n_value < 0 || n_value > MAX_N { return -1 }
	n := int(n_value)
	size := 1 << n
	if length != c.size_t(1+2*size) { return -1 }
	for index := 0; index < 2*size; index += 1 {
		value := input[1+index]
		if value < 0 || value >= MODULUS { return -1 }
	}
	output_bytes := 8*size
	if output == nil || capacity < c.size_t(output_bytes) { return -2 }

	first: [MAX_SIZE]i64
	second: [MAX_SIZE]i64
	for index := 0; index < MAX_SIZE; index += 1 { first[index] = 0; second[index] = 0 }
	for index := 0; index < size; index += 1 {
		first[index] = input[1+index]
		second[index] = input[1+size+index]
	}
	xor_walsh_transform(&first[0], size)
	xor_walsh_transform(&second[0], size)
	for index := 0; index < size; index += 1 { first[index] = (first[index] * second[index]) % MODULUS }
	xor_walsh_transform(&first[0], size)

	inverse_size := i64(1)
	for bit := 0; bit < n; bit += 1 { inverse_size = (inverse_size * ((MODULUS+1)/2)) % MODULUS }
	for index := 0; index < size; index += 1 {
		store_i64_le(output, c.size_t(8*index), (first[index] * inverse_size) % MODULUS)
	}
	return i64(output_bytes)
}
