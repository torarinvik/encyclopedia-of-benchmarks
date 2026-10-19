// Derived from the Reed-Solomon program by Simon Rockliff, 26 June 1991.
// See benchmarks/m/misc_reed_solomon/LICENSE.txt for the complete permission notice.
package misc_reed_solomon

import "core:c"

MESSAGE_BYTES :: 188
PARITY_BYTES :: 16
CODEWORD_BYTES :: 204
FULL_BYTES :: 255

make_tables :: proc(alpha, index_of: [^]i32) {
	polynomial := [8]i32{1, 0, 1, 1, 1, 0, 0, 0}
	for i := 0; i < 256; i += 1 do index_of[i] = -1
	mask := i32(1)
	alpha_8 := i32(0)
	for i := 0; i < 8; i += 1 {
		alpha[i] = mask
		index_of[int(alpha[i])] = i32(i)
		if polynomial[i] != 0 do alpha_8 ^= mask
		mask <<= 1
	}
	alpha[8] = alpha_8
	index_of[int(alpha_8)] = 8
	mask >>= 1
	for i := 9; i < FULL_BYTES; i += 1 {
		if alpha[i - 1] >= mask do alpha[i] = alpha_8 ~ ((alpha[i - 1] ~ mask) << 1)
		else do alpha[i] = alpha[i - 1] << 1
		index_of[int(alpha[i])] = i32(i)
	}
	index_of[0] = -1
}

make_generator :: proc(alpha, index_of, generator: [^]i32) {
	generator[0] = 2
	generator[1] = 1
	for root := 2; root <= PARITY_BYTES; root += 1 {
		generator[root] = 1
		for index := root - 1; index > 0; index -= 1 {
			if generator[index] != 0 {
				generator[index] = generator[index - 1] ~ alpha[int((index_of[int(generator[index])] + i32(root)) % i32(FULL_BYTES))]
			} else {
				generator[index] = generator[index - 1]
			}
		}
		generator[0] = alpha[int((index_of[int(generator[0])] + i32(root)) % i32(FULL_BYTES))]
	}
	for index := 0; index <= PARITY_BYTES; index += 1 do generator[index] = index_of[int(generator[index])]
}

encode :: proc(values: [^]i64, alpha, index_of, generator, codeword: [^]i32) {
	data: [239]i32 = {}
	parity: [PARITY_BYTES]i32 = {}
	for index := 0; index < MESSAGE_BYTES; index += 1 do data[51 + index] = i32(values[index])
	for data_index := 238; data_index >= 0; data_index -= 1 {
		feedback := index_of[int(data[data_index] ~ parity[15])]
		if feedback != -1 {
			for parity_index := 15; parity_index > 0; parity_index -= 1 {
				if generator[parity_index] != -1 {
					parity[parity_index] = parity[parity_index - 1] ~ alpha[int((generator[parity_index] + feedback) % i32(FULL_BYTES))]
				} else {
					parity[parity_index] = parity[parity_index - 1]
				}
			}
			parity[0] = alpha[int((generator[0] + feedback) % i32(FULL_BYTES))]
		} else {
			for parity_index := 15; parity_index > 0; parity_index -= 1 do parity[parity_index] = parity[parity_index - 1]
			parity[0] = 0
		}
	}
	for index := 0; index < MESSAGE_BYTES; index += 1 do codeword[index] = i32(values[index])
	for index := 0; index < PARITY_BYTES; index += 1 do codeword[MESSAGE_BYTES + index] = parity[index]
}

multiply :: proc(left, right: i32, alpha, index_of: [^]i32) -> i32 {
	if left == 0 || right == 0 do return 0
	exponent := index_of[int(left)] + index_of[int(right)]
	if exponent >= FULL_BYTES do exponent -= i32(FULL_BYTES)
	return alpha[int(exponent)]
}

divide :: proc(left, right: i32, alpha, index_of: [^]i32) -> i32 {
	if left == 0 do return 0
	exponent := index_of[int(left)] - index_of[int(right)]
	if exponent < 0 do exponent += i32(FULL_BYTES)
	return alpha[int(exponent)]
}

correct_one :: proc(codeword: [^]i32, expected_position: int, alpha, index_of: [^]i32) -> bool {
	syndrome_1 := i32(0)
	syndrome_2 := i32(0)
	for full_position := 0; full_position < FULL_BYTES; full_position += 1 {
		symbol := i32(0)
		if full_position < PARITY_BYTES do symbol = codeword[MESSAGE_BYTES + full_position]
		else if full_position >= 67 do symbol = codeword[full_position - 67]
		syndrome_1 ^= multiply(symbol, alpha[full_position % FULL_BYTES], alpha, index_of)
		syndrome_2 ^= multiply(symbol, alpha[(2 * full_position) % FULL_BYTES], alpha, index_of)
	}
	if syndrome_1 == 0 && syndrome_2 == 0 do return true
	if syndrome_1 == 0 do return false
	location := divide(syndrome_2, syndrome_1, alpha, index_of)
	full_position := -1
	for index := 0; index < FULL_BYTES; index += 1 {
		if alpha[index] == location { full_position = index; break }
	}
	if full_position < 0 do return false
	transmitted_position := 0
	if full_position < PARITY_BYTES do transmitted_position = MESSAGE_BYTES + full_position
	else if full_position >= 67 do transmitted_position = full_position - 67
	else do return false
	if transmitted_position != expected_position do return false
	magnitude := divide(syndrome_1, alpha[full_position], alpha, index_of)
	codeword[transmitted_position] ^= magnitude
	return true
}

@(export, link_name="misc_reed_solomon")
misc_reed_solomon :: proc "c" (values: [^]i64, length: c.size_t,
							 output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || (length != 189 && length != 191) do return -1
	for index := 0; index < MESSAGE_BYTES; index += 1 {
		if values[index] < 0 || values[index] > 255 do return -1
	}
	error_count := values[MESSAGE_BYTES]
	if (error_count == 0 && length != 189) || (error_count == 1 && length != 191) ||
		(error_count != 0 && error_count != 1) do return -1
	error_position := -1
	if error_count == 1 {
		if values[189] < 0 || values[189] >= CODEWORD_BYTES || values[190] < 0 || values[190] > 255 do return -1
		error_position = int(values[189])
	}
	if output == nil || output_capacity < CODEWORD_BYTES do return -2

	alpha: [FULL_BYTES]i32 = {}
	index_of: [256]i32 = {}
	generator: [PARITY_BYTES + 1]i32 = {}
	staged: [CODEWORD_BYTES]i32 = {}
	make_tables(&alpha[0], &index_of[0])
	make_generator(&alpha[0], &index_of[0], &generator[0])
	encode(values, &alpha[0], &index_of[0], &generator[0], &staged[0])
	if error_count == 1 do staged[error_position] = i32(values[190])
	if !correct_one(&staged[0], error_position, &alpha[0], &index_of[0]) do return -1
	for index := 0; index < CODEWORD_BYTES; index += 1 do output[index] = u8(staged[index])
	return i64(CODEWORD_BYTES)
}
