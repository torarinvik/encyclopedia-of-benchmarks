module ones_minus_zeros

const max_cells = 100_000
const max_dimension = 100_000

fn read_count(output &u8, cell int) i64 {
	position := 4 * cell
	return i64(output[position]) | (i64(output[position + 1]) << 8) |
		(i64(output[position + 2]) << 16) | (i64(output[position + 3]) << 24)
}

fn write_i32_le(output &u8, cell int, value i64) {
	mut encoded := value
	if encoded < 0 { encoded += 4_294_967_296 }
	position := 4 * cell
	output[position] = u8(encoded & 255)
	output[position + 1] = u8((encoded >> 8) & 255)
	output[position + 2] = u8((encoded >> 16) & 255)
	output[position + 3] = u8((encoded >> 24) & 255)
}

@[export: 'ones_minus_zeros']
pub fn ones_minus_zeros(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 { return -1 }
	unsafe {
		if values[0] < 1 || values[0] > max_dimension ||
			values[1] < 1 || values[1] > max_dimension { return -1 }
		rows := int(values[0])
		columns := int(values[1])
		if rows > max_cells / columns { return -1 }
		cells := rows * columns
		if length != usize(2 + cells) { return -1 }
		for cell in 0 .. cells {
			value := values[2 + cell]
			if value != 0 && value != 1 { return -1 }
		}
		required := usize(4 * cells)
		if output_capacity < required { return -2 }
		for byte in 0 .. 4 * cells { output[byte] = 0 }

		mut row_zero_ones := i64(0)
		mut column_zero_ones := i64(0)
		for row in 0 .. rows {
			for column in 0 .. columns {
				if values[2 + row * columns + column] == 0 { continue }
				if row == 0 {
					row_zero_ones++
				} else {
					slot := row * columns
					write_i32_le(output, slot, read_count(output, slot) + 1)
				}
			if column == 0 {
				column_zero_ones++
			} else {
				write_i32_le(output, column, read_count(output, column) + 1)
			}
		}
		for row := rows - 1; row > 0; row-- {
			row_slot := row * columns
			row_ones := read_count(output, row_slot)
			for column in 0 .. columns {
				mut column_ones := column_zero_ones
				if column != 0 { column_ones = read_count(output, column) }
				difference := 2 * row_ones + 2 * column_ones - i64(rows) - i64(columns)
				write_i32_le(output, row_slot + column, difference)
			}
		}
		for column in 0 .. columns {
			mut column_ones := column_zero_ones
			if column != 0 { column_ones = read_count(output, column) }
			difference := 2 * row_zero_ones + 2 * column_ones - i64(rows) - i64(columns)
			write_i32_le(output, column, difference)
		}
		return i64(cells)
	}
}
