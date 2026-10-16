module main

const max_parseable_input_length = 38

@[export: 'ipconverter']
pub fn ipconverter(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_parseable_input_length { return -1 }
		mode := input[0]
		payload_length_value := input[1]
		if (mode != 0 && mode != 1) || payload_length_value < 0 || payload_length_value > 35 { return -1 }
		payload_length := int(payload_length_value)
		if int(length) != payload_length + 2 { return -1 }

		mut octets := [4]i64{}
		mut position := 0
		if mode == 0 {
			if payload_length < 7 || payload_length > 15 { return -1 }
			for octet in 0 .. 4 {
				mut digits := 0
				mut value := i64(0)
				for position < payload_length && input[2 + position] != 46 {
					byte := input[2 + position]
					if digits == 3 || byte < 48 || byte > 57 { return -1 }
					value = value * 10 + byte - 48
					if value > 255 { return -1 }
					digits++
					position++
				}
				if digits == 0 { return -1 }
				octets[octet] = value
				if octet < 3 {
					if position >= payload_length || input[2 + position] != 46 { return -1 }
					position++
				} else if position != payload_length { return -1 }
			}
		} else {
			if payload_length != 35 { return -1 }
			for octet in 0 .. 4 {
				mut value := i64(0)
				for _ in 0 .. 8 {
					byte := input[2 + position]
					position++
					if byte != 48 && byte != 49 { return -1 }
					value = value * 2 + byte - 48
				}
				octets[octet] = value
				if octet < 3 {
					if input[2 + position] != 46 { return -1 }
					position++
				}
			}
			if position != payload_length { return -1 }
		}

		mut output_length := 3
		if mode == 0 {
			output_length = 35
		} else {
			for value in octets {
				if value >= 100 { output_length += 2 }
				else if value >= 10 { output_length++ }
			}
		}
		if capacity < output_length || output == nil { return -2 }

		position = 0
		for octet in 0 .. 4 {
			if mode == 0 {
				for bit in 0 .. 8 {
					shift := 7 - bit
					output[position] = u8(48 + ((octets[octet] >> shift) & 1))
					position++
				}
			} else {
				mut value := octets[octet]
				if value >= 100 { output[position] = u8(48 + value / 100); position++; value %= 100 }
				if value >= 10 { output[position] = u8(48 + value / 10); position++; value %= 10 }
				output[position] = u8(48 + value)
				position++
			}
			if octet < 3 { output[position] = u8(46); position++ }
		}
		return i64(position)
	}
}
