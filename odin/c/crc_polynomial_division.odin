package crc_polynomial_division

import "core:c"

@(export)
crc_polynomial_division :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 3+64+16 do return -1
	operation, raw_message_length, raw_polynomial_length := input[0], input[1], input[2]
	if operation < 0 || operation > 1 || raw_message_length < 1 || raw_message_length > 64 ||
		raw_polynomial_length < 2 || raw_polynomial_length > 16 {
		return -1
	}
	message_length, polynomial_length := int(raw_message_length), int(raw_polynomial_length)
	if length != c.size_t(3+message_length+polynomial_length) do return -1

	message: [64]u8 = {}
	polynomial: [16]u8 = {}
	dividend: [79]u8 = {}
	remainder: [16]u8 = {}
	for i := 0; i < message_length; i += 1 {
		bit := input[3+i]
		if bit < 0 || bit > 1 do return -1
		message[i] = u8(bit)
	}
	for i := 0; i < polynomial_length; i += 1 {
		bit := input[3+message_length+i]
		if bit < 0 || bit > 1 do return -1
		polynomial[i] = u8(bit)
	}
	if polynomial[0] != 1 || polynomial[polynomial_length-1] != 1 do return -1

	dividend_length := message_length
	for i := 0; i < message_length; i += 1 { dividend[i] = message[i] }
	if operation == 0 {
		for index := 0; index < polynomial_length-1; index += 1 {
			dividend[dividend_length] = 0
			dividend_length += 1
		}
	}
	remainder_length, cursor := 0, 0
	for cursor < dividend_length {
		for remainder_length < polynomial_length && cursor < dividend_length {
			remainder[remainder_length] = dividend[cursor]
			remainder_length += 1
			cursor += 1
		}
		if remainder_length == polynomial_length {
			if remainder[0] == 1 {
				for i := 0; i < polynomial_length; i += 1 {
					if remainder[i] == polynomial[i] { remainder[i] = 0 } else { remainder[i] = 1 }
				}
			}
			leading_zeroes := 0
			for leading_zeroes < remainder_length && remainder[leading_zeroes] == 0 { leading_zeroes += 1 }
			for i := leading_zeroes; i < remainder_length; i += 1 { remainder[i-leading_zeroes] = remainder[i] }
			remainder_length -= leading_zeroes
		}
	}

	output_length := message_length + remainder_length
	if operation == 1 { output_length = 1 }
	if output == nil || capacity < c.size_t(output_length) { return -2 }
	if operation == 0 {
		for i := 0; i < message_length; i += 1 { output[i] = message[i] }
		for i := 0; i < remainder_length; i += 1 { output[message_length+i] = remainder[i] }
	} else {
		nonzero: u8 = 0
		for i := 0; i < remainder_length; i += 1 { nonzero |= remainder[i] }
		output[0] = u8(nonzero != 0)
	}
	return i64(output_length)
}
