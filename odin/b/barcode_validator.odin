package barcode_validator

import "core:c"

get_check_digit :: proc(input: i64) -> i64 {
	barcode := input / 10
	checker := false
	total := i64(0)
	for barcode != 0 {
		multiplier := i64(3)
		if checker { multiplier = 1 }
		total += multiplier * (barcode % 10)
		barcode /= 10
		checker = !checker
	}
	return (10 - total % 10) % 10
}

decimal_length :: proc(input: i64) -> c.size_t {
	value := input
	length := c.size_t(1)
	for value >= 10 {
		value /= 10
		length += 1
	}
	return length
}

@(export)
barcode_validator :: proc "contextless" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 2 || values[0] < 0 || values[0] > 1 || values[1] < 0 do return -1
	operation, barcode := values[0], values[1]
	if operation == 0 do return get_check_digit(barcode)
	if decimal_length(barcode) == 13 && get_check_digit(barcode) == barcode % 10 do return 1
	return 0
}
