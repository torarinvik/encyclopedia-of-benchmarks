module jaccard_distance

@[export: 'jaccard_distance']
pub fn jaccard_distance(values &i64, length usize) f64 {
	if length < 2 { return -1.0e300 }
	left_value := unsafe { values[0] }
	right_value := unsafe { values[1] }
	if left_value < 0 || left_value > 64 || right_value < 0 || right_value > 64 { return -1.0e300 }
	left_length := usize(left_value)
	right_length := usize(right_value)
	if length != 2 + left_length + right_length { return -1.0e300 }
	for i in 0 .. left_length { value := unsafe { values[2 + i] }; if value < 32 || value > 126 { return -1.0e300 } }
	for j in 0 .. right_length { value := unsafe { values[2 + left_length + j] }; if value < 32 || value > 126 { return -1.0e300 } }

	mut intersection := usize(0)
	mut union_length := usize(0)
	for i in 0 .. left_length {
		value := unsafe { values[2 + i] }
		mut seen_before := false
		for k in 0 .. i { if unsafe { values[2 + k] == value } { seen_before = true; break } }
		if !seen_before {
			union_length++
			for j in 0 .. right_length { if value == unsafe { values[2 + left_length + j] } { intersection++; break } }
		}
	}
	for j in 0 .. right_length {
		value := unsafe { values[2 + left_length + j] }
		mut seen_before := false
		for k in 0 .. j { if unsafe { values[2 + left_length + k] == value } { seen_before = true; break } }
		if !seen_before {
			mut in_left := false
			for i in 0 .. left_length { if unsafe { values[2 + i] == value } { in_left = true; break } }
			if !in_left { union_length++ }
		}
	}
	if union_length == 0 { return 0.0 }
	return 1.0 - f64(intersection) / f64(union_length)
}
