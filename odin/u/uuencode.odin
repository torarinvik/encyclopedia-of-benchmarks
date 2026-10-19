package uuencode

import "core:c"

MAX_INPUT_BYTES :: 4096

symbol :: proc(value: u32) -> u8 {
	return u8(32 + (value & 63))
}

@(export)
uuencode :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length > MAX_INPUT_BYTES do return -1
	for i: c.size_t = 0; i < length; i += 1 {
		if input[i] < 0 || input[i] > 255 do return -1
	}
	needed := c.size_t(22 + 4 * ((length + 2) / 3) + 2 * ((length + 44) / 45) + 5)
	if output == nil || capacity < needed do return -2

	header := "begin 640 uuencode.c \n"
	trailer := " \nend"
	mut written: c.size_t = 0
	for i := 0; i < len(header); i += 1 {
		output[written] = header[i]
		written += 1
	}
	mut start: c.size_t = 0
	for start < length {
		mut line_len := length - start
		if line_len > 45 do line_len = 45
		stop := start + line_len
		output[written] = symbol(u32(line_len))
		written += 1
		mut index := start
		for index < stop {
			a := u32(input[index])
			has_b := index + 1 < stop
			has_c := index + 2 < stop
			b := if has_b { u32(input[index + 1]) } else { u32(0) }
			cc := if has_c { u32(input[index + 2]) } else { u32(0) }
			output[written] = symbol(a >> 2); written += 1
			output[written] = symbol((a << 4) | (b >> 4)); written += 1
			output[written] = if has_b { symbol((b << 2) | (cc >> 6)) } else { u8('=') }; written += 1
			output[written] = if has_c { symbol(cc) } else { u8('=') }; written += 1
			index += 3
		}
		output[written] = '\n'; written += 1
		start = stop
	}
	for i := 0; i < len(trailer); i += 1 {
		output[written] = trailer[i]
		written += 1
	}
	return i64(written)
}
