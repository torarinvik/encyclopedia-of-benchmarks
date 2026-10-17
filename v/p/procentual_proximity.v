module procentual_proximity

import math

const max_rows = 64
const max_columns = 8

fn write_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.f64_bits(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'procentual_proximity']
pub fn procentual_proximity(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 522 { return -1 }
		row_value := input[0]
		column_value := input[1]
		if row_value < 1 || row_value > max_rows || column_value < 1 || column_value > max_columns { return -1 }
		rows := int(row_value)
		columns := int(column_value)
		if int(length) != 2 + columns + rows * columns { return -1 }
		for column in 0 .. columns {
			weight := input[2 + column]
			if weight != 0 && weight != 1 { return -1 }
		}
		mut data := [max_rows][max_columns]f64{}
		for row in 0 .. rows {
			for column in 0 .. columns {
				value := input[2 + columns + row * columns + column]
				if value < -10000 || value > 10000 { return -1 }
				data[row][column] = f64(value)
			}
		}
		output_length := rows * (columns + 1) * 8
		if output == nil || output_capacity < usize(output_length) { return -2 }

		mut scores := [max_rows]f64{}
		for column in 0 .. columns {
			mut minimum := data[0][column]
			mut maximum := data[0][column]
			for row in 1 .. rows {
				if data[row][column] < minimum { minimum = data[row][column] }
				if data[row][column] > maximum { maximum = data[row][column] }
			}
			weight := input[2 + column]
			if minimum == maximum {
				if weight == 0 {
					for row in 0 .. rows { scores[row] += 1.0 }
				}
			} else {
				value_range := maximum - minimum
				for row in 0 .. rows {
					mut item_score := (data[row][column] - minimum) / value_range
					if weight == 0 { item_score = 1.0 - item_score }
					scores[row] = scores[row] + item_score
				}
			}
		}
		mut offset := 0
		for row in 0 .. rows {
			for column in 0 .. columns {
				write_f64_le(mut output, offset, data[row][column])
				offset += 8
			}
			write_f64_le(mut output, offset, scores[row])
			offset += 8
		}
		return i64(output_length)
	}
}
