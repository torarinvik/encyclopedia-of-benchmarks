package jaccard_distance

import "core:c"

@(export)
jaccard_distance :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 2 do return -1.0e300
	left_value := values[0]
	right_value := values[1]
	if left_value < 0 || left_value > 64 || right_value < 0 || right_value > 64 do return -1.0e300
	left_length := c.size_t(left_value)
	right_length := c.size_t(right_value)
	if length != 2 + left_length + right_length do return -1.0e300
	for i in 0..<left_length { if values[2 + i] < 32 || values[2 + i] > 126 do return -1.0e300 }
	for j in 0..<right_length { if values[2 + left_length + j] < 32 || values[2 + left_length + j] > 126 do return -1.0e300 }

	intersection := c.size_t(0)
	union_length := c.size_t(0)
	for i in 0..<left_length {
		seen_before := false
		for k in 0..<i { if values[2 + k] == values[2 + i] { seen_before = true; break } }
		if !seen_before {
			union_length += 1
			for j in 0..<right_length { if values[2 + i] == values[2 + left_length + j] { intersection += 1; break } }
		}
	}
	for j in 0..<right_length {
		seen_before := false
		for k in 0..<j { if values[2 + left_length + k] == values[2 + left_length + j] { seen_before = true; break } }
		if !seen_before {
			in_left := false
			for i in 0..<left_length { if values[2 + i] == values[2 + left_length + j] { in_left = true; break } }
			if !in_left do union_length += 1
		}
	}
	if union_length == 0 do return 0.0
	return 1.0 - f64(intersection) / f64(union_length)
}
