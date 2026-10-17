package shuf

import "core:c"

MAX_INPUT_LENGTH :: 67

write_i32_le :: proc(output: [^]u8, index: int, value: i32) {
	bits := transmute(u32)value
	offset := index * 4
	for byte := 0; byte < 4; byte += 1 { output[offset+byte] = u8(bits >> u32(8*byte)) }
}

@(export)
shuf :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	count_raw, sample_size_raw := input[0], input[1]
	if count_raw < 0 || count_raw > 32 || sample_size_raw < 1 || sample_size_raw > 32 do return -1
	count, sample_size := int(count_raw), int(sample_size_raw)
	if int(length) != 2+2*count do return -1
	items: [32]i32
	sample: [32]i32
	occupied: [32]bool
	for index in 0..<32 { occupied[index] = false }
	for index in 0..<count {
		value := input[2+index]
		if value < i64(low(i32)) || value > i64(high(i32)) do return -1
		items[index] = i32(value)
	}
	initial_count := min(count, sample_size)
	for index in 0..<initial_count {
		draw := input[2+count+index]
		if draw < 0 || draw >= i64(sample_size) do return -1
		slot := int(draw)
		for occupied[slot] {
			slot += 1
			if slot == sample_size do slot = 0
		}
		sample[slot] = items[index]
		occupied[slot] = true
	}
	if count >= sample_size {
		for index in sample_size..<count {
			draw := input[2+count+index]
			if draw < 0 || draw > i64(index) do return -1
			if draw < i64(sample_size) do sample[int(draw)] = items[index]
		}
	}
	output_bytes := initial_count*4
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	output_count := 0
	for slot in 0..<sample_size {
		if occupied[slot] {
			write_i32_le(output, output_count, sample[slot])
			output_count += 1
		}
	}
	return i64(output_count)
}
