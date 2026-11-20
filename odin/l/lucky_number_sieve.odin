package lucky_number_sieve

import "core:c"

MAX_CANDIDATES :: 2048

@(export)
lucky_number_sieve :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	mode, bound := input[0], input[1]
	if (mode != 0 && mode != 1) || bound < 0 || bound > 4096 do return -1

	candidates: [MAX_CANDIDATES]i64 = {}
	count := 0
	first: i64 = 1
	if mode == 1 do first = 2
	value := first
	for value <= bound {
		candidates[count] = value
		count += 1
		value += 2
	}

	selected := 1
	for selected < count {
		step := int(candidates[selected])
		if step > count do break
		write, rank := 0, 0
		for read := 0; read < count; read += 1 {
			rank += 1
			if rank % step != 0 {
				candidates[write] = candidates[read]
				write += 1
			}
		}
		count = write
		selected += 1
	}

	output_bytes := count * 8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < count; index += 1 {
		bits := u64(candidates[index])
		for byte := 0; byte < 8; byte += 1 {
			output[index * 8 + byte] = u8((bits >> (byte * 8)) & 255)
		}
	}
	return i64(output_bytes)
}
