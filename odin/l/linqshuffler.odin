package linqshuffler

import "core:c"

MAX_N :: 64
MAX_PARSEABLE_INPUT_LENGTH :: 67
MAX_OUTPUT_BYTES :: 520
I32_MIN :: i64(-2_147_483_648)
I32_MAX :: i64(2_147_483_647)
MBIG :: i64(2_147_483_647)

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
linqshuffler :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	n_value := input[0]
	seed := input[1]
	if n_value < 0 || n_value > MAX_N || seed < I32_MIN || seed > I32_MAX do return -1
	n := int(n_value)
	if int(input_length) != n + 2 do return -1

	var values: [MAX_N]i64
	var keys: [MAX_N]i64
	for index in 0..<n {
		value := input[index + 2]
		if value < I32_MIN || value > I32_MAX do return -1
		values[index] = value
	}

	subtraction := seed
	if seed == I32_MIN {
		subtraction = I32_MAX
	} else if seed < 0 {
		subtraction = -seed
	}
	var seed_array: [56]i64
	mj := i64(161803398) - subtraction
	seed_array[55] = mj
	mk := i64(1)
	for i in 1..<55 {
		ii := (21 * i) % 55
		seed_array[ii] = mk
		mk = mj - mk
		if mk < 0 { mk += MBIG }
		mj = seed_array[ii]
	}
	for pass in 0..<4 {
		for i in 1..<56 {
			offset_index := 1 + (i + 30) % 55
			seed_array[i] -= seed_array[offset_index]
			if seed_array[i] < 0 { seed_array[i] += MBIG }
		}
	}

	inext := 0
	inextp := 21
	for index in 0..<n {
		inext += 1
		if inext >= 56 { inext = 1 }
		inextp += 1
		if inextp >= 56 { inextp = 1 }
		sample := seed_array[inext] - seed_array[inextp]
		if sample == MBIG { sample -= 1 }
		if sample < 0 { sample += MBIG }
		seed_array[inext] = sample
		keys[index] = sample
	}

	// Strict comparison preserves input order for equal random keys.
	for index := 1; index < n; index += 1 {
		key := keys[index]
		value := values[index]
		cursor := index
		for cursor > 0 && keys[cursor - 1] > key {
			keys[cursor] = keys[cursor - 1]
			values[cursor] = values[cursor - 1]
			cursor -= 1
		}
		keys[cursor] = key
		values[cursor] = value
	}

	output_bytes := 8 * (n + 1)
	if output_bytes > MAX_OUTPUT_BYTES || output == nil || int(output_capacity) < output_bytes do return -2
	store_i64_le(output, 0, n_value)
	for index in 0..<n { store_i64_le(output, 8 * (index + 1), values[index]) }
	return i64(output_bytes)
}
