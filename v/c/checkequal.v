module main

const max_dimension = 32
const max_input_length = 2053

@[export: 'checkequal']
pub fn checkequal(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 4 || length > max_input_length {
			return -1
		}
		rows_a := int(values[0])
		columns_a := int(values[1])
		rows_b := int(values[2])
		columns_b := int(values[3])
		if rows_a < 0 || rows_a > max_dimension || columns_a < 0 || columns_a > max_dimension ||
			rows_b < 0 || rows_b > max_dimension || columns_b < 0 || columns_b > max_dimension {
			return -1
		}
		count_a := rows_a * columns_a
		count_b := rows_b * columns_b
		if length != usize(4 + count_a + count_b) {
			return -1
		}
		if rows_a != rows_b || columns_a != columns_b {
			return 0
		}
		for index in 0 .. count_a {
			if values[index + 4] != values[index + 4 + count_a] {
				return 0
			}
		}
		return 1
	}
}
