package jaccard_similarity

import "core:c"

@(export)
jaccard_similarity :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 2 do return -1.0e300
	left_value := values[0]
	right_value := values[1]
	if left_value < 0 || left_value > 64 || right_value < 0 || right_value > 64 || (left_value == 0 && right_value == 0) do return -1.0e300
	left_length := c.size_t(left_value)
	right_length := c.size_t(right_value)
	if length != 2 + left_length + right_length do return -1.0e300

	for i in 0..<left_length {
		value := values[2 + i]
		if value < 32 || value > 126 do return -1.0e300
		for before in 0..<i {
			if values[2 + before] == value do return -1.0e300
		}
	}
	for i in 0..<right_length {
		value := values[2 + left_length + i]
		if value < 32 || value > 126 do return -1.0e300
		for before in 0..<i {
			if values[2 + left_length + before] == value do return -1.0e300
		}
	}

	intersection := c.size_t(0)
	for i in 0..<left_length {
		for j in 0..<right_length {
			if values[2 + i] == values[2 + left_length + j] {
				intersection += 1
				break
			}
		}
	}
	union_length := left_length + right_length - intersection
	return f64(intersection) / f64(union_length)
}
