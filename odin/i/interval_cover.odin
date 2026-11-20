// Greedy minimum subfamily covering a half-open target interval.
package interval_cover

import "core:c"

@(export)
interval_cover :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 36 do return -2
	target_left := input[0]
	target_right := input[1]
	count_value := input[2]
	if target_left < 0 || target_left > target_right || target_right > 32 || count_value < 0 || count_value > 16 do return -2
	count := int(count_value)
	if int(length) != 3 + 2 * count do return -2
	for i := 0; i < count; i += 1 {
		left := input[3 + 2 * i]
		right := input[4 + 2 * i]
		if left < 0 || left >= right || right > 32 do return -2
	}
	if target_left == target_right do return 0

	frontier := target_left
	selected: i64 = 0
	for frontier < target_right {
		farthest := frontier
		for i := 0; i < count; i += 1 {
			left := input[3 + 2 * i]
			right := input[4 + 2 * i]
			if left <= frontier && right > farthest do farthest = right
		}
		if farthest == frontier do return -1
		frontier = farthest
		selected += 1
	}
	return selected
}
