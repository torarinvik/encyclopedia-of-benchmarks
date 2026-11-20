package max_sum_rectangle_no_larger_than_k

import "core:c"

MAX_ROWS :: 8
MAX_COLUMNS :: 8
NO_FEASIBLE :: i64(-1025)
INVALID_INPUT :: i64(-1026)

best_subarray_at_most :: proc(values: [MAX_COLUMNS]i64, count: int, limit: i64) -> i64 {
	prefixes: [MAX_COLUMNS + 1]i64
	prefix_count := 1
	running := i64(0)
	best := NO_FEASIBLE
	for i := 0; i < count; i += 1 {
		running += values[i]
		threshold := running - limit
		low, high := 0, prefix_count
		for low < high {
			middle := low + (high-low)/2
			if prefixes[middle] < threshold { low = middle + 1 } else { high = middle }
		}
		if low < prefix_count {
			candidate := running - prefixes[low]
			if best == NO_FEASIBLE || candidate > best { best = candidate }
		}
		insert := prefix_count
		for insert > 0 && prefixes[insert-1] > running {
			prefixes[insert] = prefixes[insert-1]
			insert -= 1
		}
		prefixes[insert] = running
		prefix_count += 1
	}
	return best
}

@(export)
max_sum_rectangle_no_larger_than_k :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 68 do return INVALID_INPUT
	rows_value, columns_value, limit := input[0], input[1], input[2]
	if rows_value < 1 || rows_value > MAX_ROWS || columns_value < 1 || columns_value > MAX_COLUMNS
		|| limit < -1024 || limit > 1024 do return INVALID_INPUT
	rows, columns := int(rows_value), int(columns_value)
	if int(length) != 3 + rows*columns do return INVALID_INPUT
	matrix: [MAX_ROWS][MAX_COLUMNS]i64
	for row := 0; row < rows; row += 1 {
		for column := 0; column < columns; column += 1 {
			value := input[3 + row*columns + column]
			if value < -16 || value > 16 do return INVALID_INPUT
			matrix[row][column] = value
		}
	}
	short_dimension := min(rows, columns)
	long_dimension := max(rows, columns)
	best := NO_FEASIBLE
	for first := 0; first < short_dimension; first += 1 {
		compressed: [MAX_COLUMNS]i64
		for last := first; last < short_dimension; last += 1 {
			for offset := 0; offset < long_dimension; offset += 1 {
				if rows <= columns do compressed[offset] += matrix[last][offset]
				else do compressed[offset] += matrix[offset][last]
			}
			candidate := best_subarray_at_most(compressed, long_dimension, limit)
			if candidate != NO_FEASIBLE && (best == NO_FEASIBLE || candidate > best) {
				best = candidate
				if best == limit do return best
			}
		}
	}
	return best
}
