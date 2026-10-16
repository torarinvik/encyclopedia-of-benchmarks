module crc_polynomial_division

@[export: 'crc_polynomial_division']
pub fn crc_polynomial_division(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 3 + 64 + 16 { return -1 }
	unsafe {
		operation := input[0]
		raw_message_length := input[1]
		raw_polynomial_length := input[2]
		if operation < 0 || operation > 1 || raw_message_length < 1 || raw_message_length > 64 ||
			raw_polynomial_length < 2 || raw_polynomial_length > 16 { return -1 }
		message_length, polynomial_length := int(raw_message_length), int(raw_polynomial_length)
		if length != usize(3 + message_length + polynomial_length) { return -1 }

		mut message := [64]u8{}
		mut polynomial := [16]u8{}
		mut dividend := [79]u8{}
		mut remainder := [16]u8{}
		for i in 0 .. message_length {
			bit := input[3 + i]
			if bit < 0 || bit > 1 { return -1 }
			message[i] = u8(bit)
		}
		for i in 0 .. polynomial_length {
			bit := input[3 + message_length + i]
			if bit < 0 || bit > 1 { return -1 }
			polynomial[i] = u8(bit)
		}
		if polynomial[0] != 1 || polynomial[polynomial_length - 1] != 1 { return -1 }

		mut dividend_length := message_length
		for i in 0 .. message_length { dividend[i] = message[i] }
		if operation == 0 {
			for _ in 0 .. polynomial_length - 1 {
				dividend[dividend_length] = 0
				dividend_length++
			}
		}
		mut remainder_length := 0
		mut cursor := 0
		for cursor < dividend_length {
			for remainder_length < polynomial_length && cursor < dividend_length {
				remainder[remainder_length] = dividend[cursor]
				remainder_length++
				cursor++
			}
			if remainder_length == polynomial_length {
				if remainder[0] == 1 {
					for i in 0 .. polynomial_length { remainder[i] = remainder[i] ^ polynomial[i] }
				}
				mut leading_zeroes := 0
				for leading_zeroes < remainder_length && remainder[leading_zeroes] == 0 { leading_zeroes++ }
				for i in leading_zeroes .. remainder_length { remainder[i - leading_zeroes] = remainder[i] }
				remainder_length -= leading_zeroes
			}
		}

		mut output_length := message_length + remainder_length
		if operation == 1 { output_length = 1 }
		if unsafe { output == nil } || capacity < usize(output_length) { return -2 }
		if operation == 0 {
			for i in 0 .. message_length { output[i] = message[i] }
			for i in 0 .. remainder_length { output[message_length + i] = remainder[i] }
		} else {
			mut nonzero := u8(0)
			for i in 0 .. remainder_length { nonzero |= remainder[i] }
			output[0] = u8(nonzero != 0)
		}
		return i64(output_length)
	}
}
