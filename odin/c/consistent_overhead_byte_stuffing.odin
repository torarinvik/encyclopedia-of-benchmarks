package consistent_overhead_byte_stuffing

import "core:c"

MAX_WORDS :: 257
MAX_PAYLOAD :: i64(255)
MAX_OUTPUT :: 257

@(export)
consistent_overhead_byte_stuffing :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_WORDS do return -1
	payload_value := input[0]
	if payload_value < 0 || payload_value > MAX_PAYLOAD do return -1
	payload_length := int(payload_value)
	if length != c.size_t(payload_length + 1) do return -1
	for index := 0; index < payload_length; index += 1 {
		if input[index + 1] < 0 || input[index + 1] > 255 do return -1
	}

	staged: [MAX_OUTPUT]u8 = {}
	written := 1
	code_position := 0
	code := u16(1)
	omitted_terminal_code := false
	for index := 0; index < payload_length; index += 1 {
		byte := u8(input[index + 1])
		if byte == 0 {
			staged[code_position] = u8(code)
			code_position = written
			written += 1
			code = 1
		} else {
			staged[written] = byte
			written += 1
			code += 1
			if code == 255 {
				staged[code_position] = 255
				if index + 1 == payload_length {
					omitted_terminal_code = true
					break
				}
				code_position = written
				written += 1
				code = 1
			}
		}
	}
	if !omitted_terminal_code do staged[code_position] = u8(code)
	if output == nil || capacity < c.size_t(written) do return -2
	for index := 0; index < written; index += 1 do output[index] = staged[index]
	return i64(written)
}
