module jaccard_similarity

@[export: 'jaccard_similarity']
pub fn jaccard_similarity(values &i64, length usize) f64 {
	if length < 2 { return -1.0e300 }
	left_value := unsafe { values[0] }
	right_value := unsafe { values[1] }
	if left_value < 0 || left_value > 64 || right_value < 0 || right_value > 64 || (left_value == 0 && right_value == 0) { return -1.0e300 }
	left_length := usize(left_value)
	right_length := usize(right_value)
	if length != 2 + left_length + right_length { return -1.0e300 }

	for i in 0 .. left_length {
		value := unsafe { values[2 + i] }
		if value < 32 || value > 126 { return -1.0e300 }
		for before in 0 .. i {
			if unsafe { values[2 + before] == value } { return -1.0e300 }
		}
	}
	for i in 0 .. right_length {
		value := unsafe { values[2 + left_length + i] }
		if value < 32 || value > 126 { return -1.0e300 }
		for before in 0 .. i {
			if unsafe { values[2 + left_length + before] == value } { return -1.0e300 }
		}
	}

	mut intersection := usize(0)
	for i in 0 .. left_length {
		left := unsafe { values[2 + i] }
		for j in 0 .. right_length {
			if left == unsafe { values[2 + left_length + j] } { intersection++; break }
		}
	}
	union_length := left_length + right_length - intersection
	return f64(intersection) / f64(union_length)
}
