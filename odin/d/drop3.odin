package main

import "core:c"

@(export)
drop3 :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 4097 || (length > 0 && values == nil) do return -1
	for i := 0; i < int(length); i += 1 {
		if values[i] < 0 || values[i] > 255 do return -1
	}
	if length > 4096 do return -1

	output_size: i64 = 0
	offsets := [8]int{0, 5, 2, 7, 4, 1, 6, 3}
	for iteration := 0; iteration < 20; iteration += 1 {
		input_index := 0
		remaining_bits := int(length) * 8
		phase := 0
		bit_buffer: u16 = 0
		output_bits := 0
		for remaining_bits >= 3 {
			remaining_bits -= 3
			offset := offsets[phase]
			if offset < 3 {
				bit_buffer |= u16(values[input_index]) << u16(8-offset)
				input_index += 1
			}
			code := (bit_buffer >> 13) & 7
			if code >= 4 do output_bits += 3
			bit_buffer <<= 3
			phase = (phase + 1) & 7
		}
		output_size = i64(output_bits >> 3)
	}
	return output_size
}
