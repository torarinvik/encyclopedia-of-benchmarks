module product_cipher

const max_text_length = 256
const max_columns = 64
const max_input_values = 259
const max_output_bytes = 315

@[export: 'product_cipher']
pub fn product_cipher(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values {
		return -1
	}
	unsafe {
		columns_value := input[0]
		text_length_value := input[1]
		if columns_value < 1 || columns_value > max_columns ||
			text_length_value < 0 || text_length_value > max_text_length {
			return -1
		}
		columns := int(columns_value)
		text_length := int(text_length_value)
		if int(length) != 2 + text_length {
			return -1
		}
		for index in 0 .. text_length {
			byte := input[2 + index]
			if byte < 0 || byte > 127 || byte == 10 || byte == 13 {
				return -1
			}
		}

		mut padded_length := 0
		if text_length > 0 {
			padded_length = ((text_length + columns - 1) / columns) * columns
		}
		if padded_length > max_output_bytes {
			return -1
		}
		if padded_length == 0 {
			return 0
		}
		if output == nil || output_capacity < usize(padded_length) {
			return -2
		}

		mut padded := [max_output_bytes]u8{}
		for index in 0 .. text_length {
			padded[index] = u8(input[2 + index] + 5)
		}
		for index in text_length .. padded_length {
			padded[index] = u8('/')
		}
		rows := padded_length / columns
		mut written := 0
		for column in 0 .. columns {
			for row in 0 .. rows {
				unsafe { output[written] = padded[column + row * columns] }
				written++
			}
		}
		return i64(written)
	}
}
