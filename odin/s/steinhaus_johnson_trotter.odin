package steinhaus_johnson_trotter

import "core:c"

MAX_LENGTH :: 6

emit_row :: proc "contextless" (values: [^]i32, length: int, output: [^]u8, offset: ^int) {
	for index := 0; index < length; index += 1 {
		bits := u32(values[index])
		for byte := 0; byte < 4; byte += 1 {
			output[offset^] = u8(bits >> (byte * 8))
		offset^ += 1
		}
	}
}

@(export)
steinhaus_johnson_trotter :: proc "c" (input: [^]i32, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length == 0 || length > MAX_LENGTH do return -1
	count := int(length)
	permutations := 1
	for factor := 2; factor <= count; factor += 1 do permutations *= factor
	required := 4 * count * permutations
	if output == nil || int(output_capacity) < required do return -2

	values: [MAX_LENGTH]i32
	inversion: [MAX_LENGTH]int
	for index := 0; index < MAX_LENGTH; index += 1 {
		inversion[index] = 0
		if index < count do values[index] = input[index]
	}
	offset := 0
	emit_row(&values[0], count, output, &offset)

	index := 1
	for index < count {
		if inversion[index] < index {
			swap_index := 0
			if index % 2 != 0 do swap_index = inversion[index]
			values[swap_index], values[index] = values[index], values[swap_index]
			emit_row(&values[0], count, output, &offset)
			inversion[index] += 1
			index = 1
		} else {
			inversion[index] = 0
			index += 1
		}
	}
	return i64(required)
}
