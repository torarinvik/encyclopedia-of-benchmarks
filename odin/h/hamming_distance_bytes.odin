package hamming_distance_bytes

import "core:c"

MAX_BYTE_LENGTH :: 1024

// Count differing byte positions in two equal-length byte strings.
@(export)
hamming_distance_bytes :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 2050 do return -1
	count_value := values[0]
	if count_value < 0 || count_value > MAX_BYTE_LENGTH ||
		length != c.size_t(1 + 2 * count_value) do return -1
	count := int(count_value)
	distance: i64 = 0
	for index := 0; index < count; index += 1 {
		left := values[index + 1]
		right := values[count + index + 1]
		if left < 0 || left > 255 || right < 0 || right > 255 do return -1
		if left != right do distance += 1
	}
	return distance
}
