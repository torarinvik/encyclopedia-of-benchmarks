module problem13_chunks

@[export: 'problem13_chunks']
pub fn problem13_chunks(values &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > 5001 { return -1 }
		if values[0] < 1 || values[0] > 5000 || usize(values[0]) != length - 1 { return -1 }

		byte_length := usize(values[0])
		for index in 0 .. int(byte_length) {
			if values[index + 1] < 48 || values[index + 1] > 57 { return -1 }
		}

		width := int(byte_length)
		if width > 50 { width = 50 }
		mut reversed := [52]u8{}
		mut reversed_length := 0
		mut carry := i64(0)
		mut remaining := width
		for remaining > 0 {
			remaining--
			position := remaining
			mut column := carry
			mut start := 0
			for start < int(byte_length) {
				mut chunk_length := int(byte_length) - start
				if chunk_length > 50 { chunk_length = 50 }
				if position < chunk_length { column += values[1 + start + position] - 48 }
				start += 50
			}
			reversed[reversed_length] = u8(column % 10)
			reversed_length++
			carry = column / 10
		}
		for carry > 0 {
			reversed[reversed_length] = u8(carry % 10)
			reversed_length++
			carry /= 10
		}

		mut output_length := reversed_length
		if output_length > 10 { output_length = 10 }
		if output == nil || capacity < usize(output_length) { return -2 }
		for index in 0 .. output_length {
			output[index] = u8(48 + int(reversed[reversed_length - 1 - index]))
		}
		return i64(output_length)
	}
}
