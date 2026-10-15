package prefix_sum2_d

import "core:c"

MAX_DIMENSION :: 16
INVALID_RESULT :: i64(-9223372036854775807 - 1)

@(export)
prefix_sum2_d :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 7 do return INVALID_RESULT
	raw_rows, raw_cols := input[0], input[1]
	if raw_rows < 1 || raw_rows > MAX_DIMENSION || raw_cols < 1 || raw_cols > MAX_DIMENSION do return INVALID_RESULT
	rows, cols := int(raw_rows), int(raw_cols)
	if length != c.size_t(2 + rows * cols + 4) do return INVALID_RESULT
	query := 2 + rows * cols
	row1v, col1v, row2v, col2v := input[query], input[query + 1], input[query + 2], input[query + 3]
	if row1v < 0 || col1v < 0 || row2v < row1v || col2v < col1v ||
		u64(row2v) >= u64(rows) || u64(col2v) >= u64(cols) do return INVALID_RESULT
	prefix: [MAX_DIMENSION + 1][MAX_DIMENSION + 1]i64
	for i := 0; i < rows; i += 1 {
		for j := 0; j < cols; j += 1 {
			value := input[2 + i * cols + j]
			if value < -1000 || value > 1000 do return INVALID_RESULT
			prefix[i + 1][j + 1] = value + prefix[i][j + 1] + prefix[i + 1][j] - prefix[i][j]
		}
	}
	row1, col1, row2, col2 := int(row1v), int(col1v), int(row2v), int(col2v)
	return prefix[row2 + 1][col2 + 1] - prefix[row1][col2 + 1] -
		prefix[row2 + 1][col1] + prefix[row1][col1]
}
