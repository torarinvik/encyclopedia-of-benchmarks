package rsk_row_insertion

import "core:c"

MAX_N :: 8
INVALID_RESULT :: i64(-9_223_372_036_854_775_807) - 1

@(export)
rsk_row_insertion :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 10 do return INVALID_RESULT
	n_value := input[0]
	if n_value < 0 || n_value > MAX_N || length != c.size_t(n_value + 1) do return INVALID_RESULT
	n := int(n_value)
	seen: [MAX_N]bool
	for i := 0; i < n; i += 1 {
		value := input[i + 1]
		if value < 0 || value >= n_value || seen[int(value)] do return INVALID_RESULT
		seen[int(value)] = true
	}
	if n == 0 do return 0

	p: [MAX_N * MAX_N]i64
	q: [MAX_N * MAX_N]i64
	row_lengths: [MAX_N]int
	row_count := 0
	for step := 1; step <= n; step += 1 {
		value := input[step] + 1
		row := 0
		for {
			if row == row_count {
				p[row * MAX_N] = value
				q[row * MAX_N] = i64(step)
				row_lengths[row] = 1
				row_count += 1
				break
			}
			column := 0
			for column < row_lengths[row] && p[row * MAX_N + column] < value {
				column += 1
			}
			if column == row_lengths[row] {
				p[row * MAX_N + column] = value
				q[row * MAX_N + column] = i64(step)
				row_lengths[row] += 1
				break
			}
			bumped := p[row * MAX_N + column]
			p[row * MAX_N + column] = value
			value = bumped
			row += 1
		}
	}

	p_row: [MAX_N]i64
	q_row: [MAX_N]i64
	for row := 0; row < row_count; row += 1 {
		for column := 0; column < row_lengths[row]; column += 1 {
			p_row[int(p[row * MAX_N + column] - 1)] = i64(row)
			q_row[int(q[row * MAX_N + column] - 1)] = i64(row)
		}
	}
	code := n_value
	for label := 0; label < n; label += 1 {
		code = code * 9 + p_row[label] + 1
		code = code * 9 + q_row[label] + 1
	}
	return code
}
