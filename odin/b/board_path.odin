package board_path

import "core:c"

@(export)
board_path :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	start, end := input[0], input[1]
	if start < 0 || end < 0 || start > 30 || end > 30 || start > end do return -1
	ways: [31]i64
	ways[int(end)] = 1
	for i := int(end) - 1; i >= int(start); i -= 1 {
		for die := 1; die <= 6 && i + die <= int(end); die += 1 { ways[i] += ways[i + die] }
	}
	return ways[int(start)]
}
