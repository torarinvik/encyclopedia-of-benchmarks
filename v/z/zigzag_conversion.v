module zigzag_conversion

const max_input_length = 1025
const max_rows = 1024

fn is_ascii_letter(value i64) bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

@[export: 'zigzag_conversion']
pub fn zigzag_conversion(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length == 0 || length > max_input_length { return -1 }
	unsafe {
		rows_value := values[0]
		if rows_value < 1 || rows_value > max_rows { return -1 }
		text_length := length - 1
		for index in 0 .. text_length {
			if !is_ascii_letter(values[index + 1]) { return -1 }
		}
		if output_capacity < text_length || (text_length != 0 && output == nil) { return -2 }
		if text_length == 0 { return 0 }
		rows := usize(rows_value)
		if rows == 1 || rows >= text_length {
			for index in 0 .. text_length { output[index] = u8(values[index + 1]) }
			return i64(text_length)
		}
		cycle := 2 * (rows - 1)
		mut written := usize(0)
		for row in 0 .. rows {
			mut index := row
			mut step := cycle
			if row > 0 && row + 1 < rows { step = cycle - 2 * row }
			for index < text_length {
				output[written] = u8(values[index + 1])
				written++
				index += step
				if row > 0 && row + 1 < rows { step = cycle - step }
			}
		}
		return i64(written)
	}
}
