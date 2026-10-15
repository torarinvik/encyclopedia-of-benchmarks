package base85

import "core:c"

MAX_INPUT_VALUES :: 66
MAX_DECODED_LENGTH :: 52

decode_group :: proc(values: [^]i64, start, count: c.size_t) -> i64 {
	value := i64(0)
	for index := c.size_t(0); index < 5; index += 1 {
		digit := i64(84)
		if index < count {
			byte := values[start + index]
			if byte < 33 || byte > 117 do return -1
			digit = byte - 33
		}
		value = value * 85 + digit
	}
	if value > 4294967295 do return -1
	return value
}

@(export)
base85 :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > MAX_INPUT_VALUES do return -1
	mode := values[0]
	payload_length := length - 1
	output_length := c.size_t(0)
	if mode == 0 {
		for index := c.size_t(1); index < length; index += 1 {
			if values[index] < 0 || values[index] > 255 do return -1
		}
		remainder := payload_length % 4
		output_length = (payload_length / 4) * 5
		if remainder != 0 do output_length += remainder + 1
	} else if mode == 1 {
		if payload_length % 5 == 1 do return -1
		for offset := c.size_t(0); offset < payload_length; {
			count := c.size_t(5)
			if payload_length - offset < 5 do count = payload_length - offset
			if decode_group(values, offset + 1, count) < 0 do return -1
			if count == 5 do output_length += 4 else do output_length += count - 1
			offset += count
		}
		if output_length > MAX_DECODED_LENGTH do return -1
	} else {
		return -1
	}
	if output_capacity < output_length || (output_length > 0 && output == nil) do return -2

	written := c.size_t(0)
	if mode == 0 {
		for offset := c.size_t(0); offset < payload_length; offset += 4 {
			count := c.size_t(4)
			if payload_length - offset < 4 do count = payload_length - offset
			value := u64(0)
			for byte := c.size_t(0); byte < 4; byte += 1 {
				value <<= 8
				if byte < count do value |= u64(values[offset + byte + 1])
			}
			place := u64(52200625)
			for digit := c.size_t(0); digit < 5; digit += 1 {
				encoded := u8(value / place + 33)
				value %= place
				if count == 4 || digit < count + 1 {
					output[written] = encoded
					written += 1
				}
				if digit == 0 do place = 614125
				else if digit == 1 do place = 7225
				else if digit == 2 do place = 85
				else do place = 1
			}
		}
	} else {
		for offset := c.size_t(0); offset < payload_length; {
			count := c.size_t(5)
			if payload_length - offset < 5 do count = payload_length - offset
			value := u64(decode_group(values, offset + 1, count))
			byte_count := c.size_t(4)
			if count != 5 do byte_count = count - 1
			for byte := c.size_t(0); byte < byte_count; byte += 1 {
				output[written] = u8((value >> (24 - 8 * byte)) & 255)
				written += 1
			}
			offset += count
		}
	}
	return i64(written)
}
