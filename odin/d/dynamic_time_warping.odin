package dynamic_time_warping

import "core:c"

MAX_SERIES_LENGTH :: 16
MAX_SAMPLE_VALUE :: i64(1000)
INVALID_RESULT :: -1.0e300
UNREACHABLE :: 1.0e300

@(export)
dynamic_time_warping :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 3 || length > 35 do return INVALID_RESULT
	first_length_value := values[0]
	second_length_value := values[1]
	band_value := values[2]
	if first_length_value < 1 || first_length_value > MAX_SERIES_LENGTH ||
		second_length_value < 1 || second_length_value > MAX_SERIES_LENGTH do return INVALID_RESULT
	first_length := int(first_length_value)
	second_length := int(second_length_value)
	difference := first_length_value - second_length_value
	if difference < 0 do difference = -difference
	if band_value < difference || band_value > MAX_SERIES_LENGTH ||
		length != c.size_t(3 + first_length + second_length) do return INVALID_RESULT
	band := int(band_value)
	for index := 0; index < first_length+second_length; index += 1 {
		value := values[3+index]
		if value < -MAX_SAMPLE_VALUE || value > MAX_SAMPLE_VALUE do return INVALID_RESULT
	}

	var rows: [2][MAX_SERIES_LENGTH+1]f64
	for column := 0; column <= second_length; column += 1 do rows[0][column] = UNREACHABLE
	rows[0][0] = 0.0
	for row := 1; row <= first_length; row += 1 {
		current := row % 2
		previous := (row-1) % 2
		for column := 0; column <= second_length; column += 1 do rows[current][column] = UNREACHABLE
		start := 1
		if row > band do start = row - band
		finish := second_length
		if row + band < second_length do finish = row + band
		for column := start; column <= finish; column += 1 {
			difference_value := values[3+row-1] - values[3+first_length+column-1]
			if difference_value < 0 do difference_value = -difference_value
			best := rows[previous][column]
			if rows[current][column-1] < best do best = rows[current][column-1]
			if rows[previous][column-1] < best do best = rows[previous][column-1]
			rows[current][column] = f64(difference_value) + best
		}
	}
	return rows[first_length%2][second_length]
}
