package hamming_distance_strings

@(export)
hamming_distance_strings :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 260 do return -1
	left_length := input[0]
	right_length := input[1]
	if left_length < 0 || left_length > 128 || right_length < 0 || right_length > 128 do return -1
	if length != c.size_t(2 + left_length + right_length) do return -1
	for i in 2..<int(length) { if input[i] < 0 || input[i] > 255 do return -1 }
	if left_length != right_length do return -1
	distance := i64(0)
	for i in 0..<int(left_length) { if input[2 + i] != input[2 + int(left_length) + i] do distance += 1 }
	return distance
}
