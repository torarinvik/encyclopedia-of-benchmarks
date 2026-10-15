package max_consecutive_answers

import "core:c"

MAX_BITS :: 1024

longest_for_target :: proc "contextless" (input: [^]i64, count, allowed: int, target: i64) -> int {
	left := 0
	opposite := 0
	best := 0
	for right := 0; right < count; right += 1 {
		if input[right + 1] != target do opposite += 1
		for opposite > allowed {
			if input[left + 1] != target do opposite -= 1
			left += 1
		}
		best = max(best, right - left + 1)
	}
	return best
}

@(export)
max_consecutive_answers :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length == 0 || length > c.size_t(MAX_BITS + 1) do return -1
	count := int(length) - 1
	if input[0] < 0 || input[0] > i64(count) do return -1
	for index := 0; index < count; index += 1 {
		if input[index + 1] != 0 && input[index + 1] != 1 do return -1
	}
	allowed := int(input[0])
	return i64(max(longest_for_target(input, count, allowed, 1),
	               longest_for_target(input, count, allowed, 0)))
}
