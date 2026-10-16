package ipconverter

import "core:c"

MAX_PARSEABLE_INPUT_LENGTH :: 38

@(export)
ipconverter :: proc "c" (input: [^]i64, length: c.size_t,
                          output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	mode := input[0]
	payload_length_value := input[1]
	if (mode != 0 && mode != 1) || payload_length_value < 0 || payload_length_value > 35 do return -1
	payload_length := int(payload_length_value)
	if int(length) != payload_length + 2 do return -1

	octets: [4]i64
	position := 0
	if mode == 0 {
		if payload_length < 7 || payload_length > 15 do return -1
		for octet := 0; octet < 4; octet += 1 {
			digits := 0
			value: i64 = 0
			for position < payload_length && input[2 + position] != 46 {
				byte := input[2 + position]
				if digits == 3 || byte < 48 || byte > 57 do return -1
				value = value * 10 + byte - 48
				if value > 255 do return -1
				digits += 1
				position += 1
			}
			if digits == 0 do return -1
			octets[octet] = value
			if octet < 3 {
				if position >= payload_length || input[2 + position] != 46 do return -1
				position += 1
			} else if position != payload_length do return -1
		}
	} else {
		if payload_length != 35 do return -1
		for octet := 0; octet < 4; octet += 1 {
			value: i64 = 0
			for bit := 0; bit < 8; bit += 1 {
				byte := input[2 + position]
				position += 1
				if byte != 48 && byte != 49 do return -1
				value = value * 2 + byte - 48
			}
			octets[octet] = value
			if octet < 3 {
				if input[2 + position] != 46 do return -1
				position += 1
			}
		}
		if position != payload_length do return -1
	}

	output_length := 3
	if mode == 0 {
		output_length = 35
	} else {
		for value in octets {
			if value >= 100 do output_length += 2
			else if value >= 10 do output_length += 1
		}
	}
	if capacity < output_length || output == nil do return -2

	position = 0
	for octet := 0; octet < 4; octet += 1 {
		if mode == 0 {
			for bit := 7; bit >= 0; bit -= 1 {
				output[position] = u8(48 + ((octets[octet] >> bit) & 1))
				position += 1
			}
		} else {
			value := octets[octet]
			if value >= 100 { output[position] = u8(48 + value / 100); position += 1; value %= 100 }
			if value >= 10 { output[position] = u8(48 + value / 10); position += 1; value %= 10 }
			output[position] = u8(48 + value)
			position += 1
		}
		if octet < 3 { output[position] = u8(46); position += 1 }
	}
	return i64(position)
}
