package checkequal

import "core:c"

MAX_DIMENSION :: 32
MAX_INPUT_LENGTH :: 2053

@(export)
checkequal :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1

	rows_a := int(values[0])
	columns_a := int(values[1])
	rows_b := int(values[2])
	columns_b := int(values[3])
	if rows_a < 0 || rows_a > MAX_DIMENSION || columns_a < 0 || columns_a > MAX_DIMENSION ||
		rows_b < 0 || rows_b > MAX_DIMENSION || columns_b < 0 || columns_b > MAX_DIMENSION do return -1

	count_a := rows_a * columns_a
	count_b := rows_b * columns_b
	if int(length) != 4 + count_a + count_b do return -1
	if rows_a != rows_b || columns_a != columns_b do return 0
	for index := 0; index < count_a; index += 1 {
		if values[4 + index] != values[4 + count_a + index] do return 0
	}
	return 1
}
