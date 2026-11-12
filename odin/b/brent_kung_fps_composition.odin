package brent_kung_fps_composition

import "core:c"

MODULUS :: i64(998_244_353)
MAX_N :: 32
MAX_INPUT :: c.size_t(66)
MAX_BLOCKS :: 6
MAX_POWERS :: 7
Polynomial :: [MAX_N]i64

multiply_truncated :: proc(left, right: Polynomial, n: int) -> Polynomial {
	product: Polynomial
	for i := 0; i < n; i += 1 {
		for j := 0; j < n-i; j += 1 {
			product[i+j] = (product[i+j] + left[i]*right[j]) % MODULUS
		}
	}
	return product
}

store_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export, link_name="brent_kung_fps_composition")
brent_kung_fps_composition :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	n_value := input[0]
	if n_value < 1 || n_value > i64(MAX_N) do return -1
	n := int(n_value)
	if int(length) != 1+2*n do return -1
	for i := 0; i < 2*n; i += 1 {
		if input[i+1] < 0 || input[i+1] >= MODULUS do return -1
	}
	if input[1+n] != 0 do return -1
	bytes := 8*n
	if output == nil || int(capacity) < bytes do return -2

	block_size := 1
	for block_size*block_size < n { block_size += 1 }
	block_count := (n+block_size-1)/block_size
	powers: [MAX_POWERS]Polynomial = {}
	blocks: [MAX_BLOCKS]Polynomial = {}
	inner: Polynomial
	for degree := 0; degree < n; degree += 1 { inner[degree] = input[1+n+degree] }
	powers[0][0] = 1
	for exponent := 1; exponent <= block_size; exponent += 1 {
		powers[exponent] = multiply_truncated(powers[exponent-1], inner, n)
	}
	for block := 0; block < block_count; block += 1 {
		for offset := 0; offset < block_size; offset += 1 {
			coefficient_index := block*block_size+offset
			if coefficient_index >= n do break
			coefficient := input[1+coefficient_index]
			for degree := 0; degree < n; degree += 1 {
				blocks[block][degree] =
					(blocks[block][degree]+coefficient*powers[offset][degree])%MODULUS
			}
		}
	}
	composed := blocks[block_count-1]
	for block := block_count-1; block > 0; block -= 1 {
		composed = multiply_truncated(composed, powers[block_size], n)
		for degree := 0; degree < n; degree += 1 {
			composed[degree] = (composed[degree]+blocks[block-1][degree])%MODULUS
		}
	}
	for degree := 0; degree < n; degree += 1 { store_le(output, 8*degree, composed[degree]) }
	return i64(bytes)
}

main :: proc() {}
