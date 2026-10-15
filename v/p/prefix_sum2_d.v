module prefix_sum2_d

const max_dimension = 16
const invalid_result = i64(-9223372036854775807 - 1)

@[export: 'prefix_sum2_d']
pub fn prefix_sum2_d(input &i64, length usize) i64 {
	if length < 7 { return invalid_result }
	unsafe {
		raw_rows := input[0]
		raw_cols := input[1]
		if raw_rows < 1 || raw_rows > max_dimension || raw_cols < 1 || raw_cols > max_dimension { return invalid_result }
		rows, cols := int(raw_rows), int(raw_cols)
		if length != 2 + rows * cols + 4 { return invalid_result }
		query := 2 + rows * cols
		row1v, col1v, row2v, col2v := input[query], input[query + 1], input[query + 2], input[query + 3]
		if row1v < 0 || col1v < 0 || row2v < row1v || col2v < col1v ||
			u64(row2v) >= u64(rows) || u64(col2v) >= u64(cols) { return invalid_result }
		mut prefix := [max_dimension + 1][max_dimension + 1]i64{}
		for i in 0 .. rows {
			for j in 0 .. cols {
				value := input[2 + i * cols + j]
				if value < -1000 || value > 1000 { return invalid_result }
				prefix[i + 1][j + 1] = value + prefix[i][j + 1] + prefix[i + 1][j] - prefix[i][j]
			}
		}
		row1, col1, row2, col2 := int(row1v), int(col1v), int(row2v), int(col2v)
		return prefix[row2 + 1][col2 + 1] - prefix[row1][col2 + 1] -
			prefix[row2 + 1][col1] + prefix[row1][col1]
	}
}
