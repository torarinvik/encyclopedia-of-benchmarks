module hexa_decimal_to_binary

fn hex_digit(code i64) int {
	if code >= 48 && code <= 57 { return int(code - 48) }
	if code >= 65 && code <= 70 { return int(code - 55) }
	if code >= 97 && code <= 102 { return int(code - 87) }
	return -1
}

@[export: 'hexa_decimal_to_binary']
pub fn hexa_decimal_to_binary(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length == 0 || length > 65 || unsafe { input == nil } { return -1 }
	unsafe {
		first_digit := if input[0] == 45 || input[0] == 43 { 1 } else { 0 }
		negative := input[0] == 45
		if first_digit == int(length) { return -1 }
		limit := if negative { u64(2147483648) } else { u64(2147483647) }
		mut value := u64(0)
		for index in first_digit .. int(length) {
			digit := hex_digit(input[index])
			if digit < 0 || value > (limit - u64(digit)) / u64(16) { return -1 }
			value = value * u64(16) + u64(digit)
		}
		mut bits := u32(value)
		if negative && value != 0 { bits = u32(u64(4294967296) - value) }
		mut width := 0
		mut remaining := bits
		for remaining != 0 {
			width++
			remaining >>= 1
		}
		if negative && value != 0 { width = 32 }
		else if width < 8 { width = 8 }
		mut buffer := [32]u8{}
		remaining = bits
		mut position := width
		for position > 0 {
			position--
			buffer[position] = u8(48 + remaining % u32(2))
			remaining >>= 1
		}
		if width > int(output_capacity) || output == nil { return -2 }
		for index in 0 .. width { output[index] = buffer[index] }
		return i64(width)
	}
}
