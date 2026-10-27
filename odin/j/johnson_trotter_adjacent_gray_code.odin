package johnson_trotter_adjacent_gray_code

import "core:c"

MAX_N :: 3
MAX_OUTPUT_BYTES :: 144

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
johnson_trotter_adjacent_gray_code :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 1 || input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	permutation_count := 1
	for value := 2; value <= n; value += 1 { permutation_count *= value }
	output_bytes := 8*n*permutation_count
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	permutation: [MAX_N]i64
	direction: [MAX_N+1]i64
	for index := 0; index < n; index += 1 { permutation[index] = i64(index+1); direction[index+1] = -1 }
	staged: [MAX_OUTPUT_BYTES]u8
	rows := 0
	for {
		for index := 0; index < n; index += 1 { store_i64_le(&staged[0], 8*(rows*n+index), permutation[index]) }
		rows += 1
		largest_mobile := i64(0)
		mobile_position := -1
		for position := 0; position < n; position += 1 {
			value := permutation[position]
			neighbor := position + int(direction[value])
			if neighbor >= 0 && neighbor < n && value > permutation[neighbor] && value > largest_mobile {
				largest_mobile, mobile_position = value, position
			}
		}
		if mobile_position < 0 do break
		neighbor := mobile_position + int(direction[largest_mobile])
		permutation[mobile_position], permutation[neighbor] = permutation[neighbor], permutation[mobile_position]
		for value := int(largest_mobile)+1; value <= n; value += 1 { direction[value] = -direction[value] }
	}
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
