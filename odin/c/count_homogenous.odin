package count_homogenous

import "core:c"

MAX_TEXT_BYTES :: 4096

// Count contiguous runs of equal ASCII bytes.
@(export)
count_homogenous :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || input[0] < 0 || input[0] > MAX_TEXT_BYTES do return -1
	count := int(input[0])
	if length != c.size_t(count + 1) do return -1
	for i := 0; i < count; i += 1 {
		if input[1 + i] < 0 || input[1 + i] > 127 do return -1
	}
	if count == 0 do return 0
	runs := 1
	for i := 2; i <= count; i += 1 {
		if input[i] != input[i - 1] do runs += 1
	}
	return i64(runs)
}
