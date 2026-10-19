package main

import "core:c"

read_bits :: proc(values: [^]i64, length, bit_offset, width: int) -> i64 {
	bit_length := length * 8
	if bit_offset < 0 || bit_offset > bit_length || width > bit_length - bit_offset do return -1
	byte_offset := bit_offset >> 3
	start := bit_offset & 7
	byte_count := (start + width + 7) >> 3
	window: u32 = 0
	for index := 0; index < byte_count; index += 1 {
		window = (window << 8) | u32(values[byte_offset + index])
	}
	shift := byte_count * 8 - start - width
	mask := (u32(1) << u32(width)) - 1
	return i64((window >> u32(shift)) & mask)
}

decode_sum :: proc(values: [^]i64, length: int) -> i64 {
	packet_count := read_bits(values, length, 0, 16)
	if packet_count < 0 || packet_count > 451 do return -1
	bit_offset := 16
	total: i64 = 0
	for packet := 0; packet < int(packet_count); packet += 1 {
		channels := read_bits(values, length, bit_offset, 5)
		if channels < 0 do return -1
		bit_offset += 5
		for channel := 0; channel < int(channels); channel += 1 {
			value := read_bits(values, length, bit_offset, 11)
			if value < 0 do return -1
			total += value
			bit_offset += 11
		}
		packet_bits := 5 + 11 * int(channels)
		bit_offset += (8 - (packet_bits & 7)) & 7
		if bit_offset > length * 8 do return -1
	}
	return total
}

@(export)
five11 :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 13524 || length > 13523 do return -1
	input_length := int(length)
	for index := 0; index < input_length; index += 1 {
		if values[index] < 0 || values[index] > 255 do return -1
	}
	result: i64 = 0
	for _ := 0; _ < 10000; _ += 1 {
		result = decode_sum(values, input_length)
		if result < 0 do return -1
	}
	return result
}
