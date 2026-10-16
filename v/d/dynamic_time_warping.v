module dynamic_time_warping

const max_series_length = 16
const max_sample_value = i64(1000)
const invalid_result = -1.0e300
const unreachable = 1.0e300

@[export: 'dynamic_time_warping']
pub fn dynamic_time_warping(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 3 || length > 35 { return invalid_result }
	first_length_value := unsafe { values[0] }
	second_length_value := unsafe { values[1] }
	band_value := unsafe { values[2] }
	if first_length_value < 1 || first_length_value > max_series_length ||
		second_length_value < 1 || second_length_value > max_series_length { return invalid_result }
	first_length := int(first_length_value)
	second_length := int(second_length_value)
	difference := first_length_value - second_length_value
	if difference < 0 { difference = -difference }
	if band_value < difference || band_value > max_series_length ||
		length != usize(3 + first_length + second_length) { return invalid_result }
	band := int(band_value)
	for index := 0; index < first_length + second_length; index++ {
		value := unsafe { values[3 + index] }
		if value < -max_sample_value || value > max_sample_value { return invalid_result }
	}

	mut rows := [2][max_series_length + 1]f64{}
	for column := 0; column <= second_length; column++ { rows[0][column] = unreachable }
	rows[0][0] = 0.0
	for row := 1; row <= first_length; row++ {
		current := row % 2
		previous := (row - 1) % 2
		for column := 0; column <= second_length; column++ { rows[current][column] = unreachable }
		mut start := 1
		if row > band { start = row - band }
		mut finish := second_length
		if row + band < second_length { finish = row + band }
		for column := start; column <= finish; column++ {
			first_sample := unsafe { values[3 + row - 1] }
			second_sample := unsafe { values[3 + first_length + column - 1] }
			difference_value := first_sample - second_sample
			if difference_value < 0 { difference_value = -difference_value }
			mut best := rows[previous][column]
			if rows[current][column - 1] < best { best = rows[current][column - 1] }
			if rows[previous][column - 1] < best { best = rows[previous][column - 1] }
			rows[current][column] = f64(difference_value) + best
		}
	}
	return rows[first_length % 2][second_length]
}
