module levenshtein_distance

// Unit-cost Levenshtein distance over two ASCII byte sequences.
@[export: 'levenshtein_distance']
pub fn levenshtein_distance(values &i64, length usize) i64 {
	if length < 2 { return -1 }
	left_length_value := unsafe { values[0] }
	right_length_value := unsafe { values[1] }
	if left_length_value < 0 || left_length_value > 255 || right_length_value < 0 || right_length_value > 255 {
		return -1
	}
	left_length := usize(left_length_value)
	right_length := usize(right_length_value)
	if length != 2 + left_length + right_length { return -1 }
	for index in 0 .. left_length {
		byte := unsafe { values[2 + index] }
		if byte < 0 || byte > 127 { return -1 }
	}
	for index in 0 .. right_length {
		byte := unsafe { values[2 + left_length + index] }
		if byte < 0 || byte > 127 { return -1 }
	}

	mut row := [256]i64{}
	for column in 0 .. right_length + 1 { row[column] = i64(column) }
	for row_index in 1 .. left_length + 1 {
		mut diagonal := row[0]
		row[0] = i64(row_index)
		for column in 1 .. right_length + 1 {
			above := row[column]
			deletion := above + 1
			insertion := row[column - 1] + 1
			left_byte := unsafe { values[2 + row_index - 1] }
			right_byte := unsafe { values[2 + left_length + column - 1] }
			substitution := diagonal + if left_byte == right_byte { i64(0) } else { i64(1) }
			mut best := if deletion < insertion { deletion } else { insertion }
			if substitution < best { best = substitution }
			row[column] = best
			diagonal = above
		}
	}
	return row[right_length]
}
