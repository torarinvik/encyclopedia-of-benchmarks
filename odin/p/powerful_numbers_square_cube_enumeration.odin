package powerful_numbers_square_cube_enumeration

import "core:c"

MAX_INPUT_WORDS :: 2
MAX_LIMIT :: i64(100)

is_squarefree :: proc(value: i64) -> bool {
	for divisor := i64(2); divisor <= value / divisor; divisor += 1 {
		if value % (divisor * divisor) == 0 do return false
	}
	return true
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
powerful_numbers_square_cube_enumeration :: proc "c" (input: [^]i64,
		length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_WORDS || length != 1 do return -1
	limit := input[0]
	if limit < 1 || limit > MAX_LIMIT do return -1

	values: [14]i64 = {}
	count := 0
	for b := i64(1); b*b*b <= limit; b += 1 {
		if !is_squarefree(b) do continue
		cube := b*b*b
		for a := i64(1); a*a*cube <= limit; a += 1 {
			values[count] = a*a*cube
			count += 1
		}
	}
	for index := 1; index < count; index += 1 {
		value := values[index]
		position := index
		for position > 0 && values[position-1] > value {
			values[position] = values[position-1]
			position -= 1
		}
		values[position] = value
	}

	output_bytes := (count + 1) * 8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	store_i64_le(output, 0, i64(count))
	for index := 0; index < count; index += 1 {
		store_i64_le(output, (index + 1) * 8, values[index])
	}
	return i64(output_bytes)
}
