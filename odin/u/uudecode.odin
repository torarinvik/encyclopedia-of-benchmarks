package uudecode

import "core:c"

MAX_INPUT_BYTES :: 4096
MAX_OUTPUT_BYTES :: 2949

scan :: proc(input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length > MAX_INPUT_BYTES do return -1
	for i: c.size_t = 0; i < length; i += 1 {
		if input[i] < 0 || input[i] > 255 do return -1
	}
	header := "begin 755 uustart.file \n"
	if length < c.size_t(len(header) + 5) do return -1
	for i := 0; i < len(header); i += 1 {
		if input[i] != i64(header[i]) do return -1
	}

	mut cursor := c.size_t(len(header))
	mut total: c.size_t = 0
	for cursor < length {
		marker := input[cursor]
		cursor += 1
		if marker == 32 {
			if cursor + 4 != length || input[cursor] != 10 || input[cursor + 1] != 101 ||
				input[cursor + 2] != 110 || input[cursor + 3] != 100 do return -1
			if total > MAX_OUTPUT_BYTES do return -1
			return i64(total)
		}
		count := marker - 32
		if count < 1 || count > 45 do return -1
		encoded := c.size_t(4 * ((count + 2) / 3))
		if cursor + encoded >= length || input[cursor + encoded] != 10 do return -1
		for i: c.size_t = 0; i < encoded; i += 1 {
			if input[cursor + i] < 32 || input[cursor + i] > 95 do return -1
		}
		total += c.size_t(count)
		if total > MAX_OUTPUT_BYTES do return -1
		cursor += encoded + 1
	}
	return -1
}

@(export)
uudecode :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	decoded_length := scan(input, length)
	if decoded_length < 0 do return -1
	if output == nil || capacity < c.size_t(decoded_length) do return -2

	header := "begin 755 uustart.file \n"
	mut cursor := c.size_t(len(header))
	mut written: c.size_t = 0
	for {
		count := c.size_t(input[cursor] - 32)
		cursor += 1
		if count == 0 do break
		encoded := c.size_t(4 * ((count + 2) / 3))
		mut emitted: c.size_t = 0
		for group: c.size_t = 0; group < encoded; group += 4 {
			a := u32(input[cursor] - 32)
			b := u32(input[cursor + 1] - 32)
			cc := u32(input[cursor + 2] - 32)
			d := u32(input[cursor + 3] - 32)
			cursor += 4
			output[written] = u8((a << 2) | (b >> 4))
			written += 1
			emitted += 1
			if emitted < count {
				output[written] = u8((b << 4) | (cc >> 2))
				written += 1
				emitted += 1
			}
			if emitted < count {
				output[written] = u8((cc << 6) | d)
				written += 1
				emitted += 1
			}
		}
		cursor += 1
	}
	return i64(written)
}
