package sparsity

import "core:c"

MAX_DIMENSION :: 63
MAX_INPUT_VALUES :: 3971
MAX_ABS_CELL :: i64(1_000_000)
INVALID_RESULT :: -1.0e300

@(export)
sparsity :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 2 || length > MAX_INPUT_VALUES do return INVALID_RESULT
	rows_value := input[0]
	columns_value := input[1]
	if rows_value < 1 || rows_value > MAX_DIMENSION || columns_value < 1 || columns_value > MAX_DIMENSION do return INVALID_RESULT
	rows := int(rows_value)
	columns := int(columns_value)
	total := rows * columns
	if length != c.size_t(2 + total) do return INVALID_RESULT

	zero_count := 0
	for index := 0; index < total; index += 1 {
		value := input[2 + index]
		if value < -MAX_ABS_CELL || value > MAX_ABS_CELL do return INVALID_RESULT
		if value == 0 do zero_count += 1
	}
	return f64(zero_count) / f64(total)
}
