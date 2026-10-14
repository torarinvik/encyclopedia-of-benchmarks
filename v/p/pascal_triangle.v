module pascal_triangle

const max_rows = 30
const hash_mod = 1_000_000_007

@[export: 'pascal_triangle_benchmark']
pub fn pascal_triangle_benchmark(values &i64, length usize) i64 {
	if length != 1 { return -1 }
	row_count_value := unsafe { values[0] }
	if row_count_value < 0 || row_count_value > max_rows { return -1 }
	row_count := int(row_count_value)
	mut row := [max_rows]i64{}
	row[0] = 1
	mut hash := i64(0)
	for row_index in 0 .. row_count {
		mut column := row_index
		for column > 0 {
			row[column] += row[column - 1]
			column--
		}
		for col in 0 .. row_index + 1 {
			hash = (hash * 31 + row[col] % hash_mod) % hash_mod
		}
	}
	return hash
}
