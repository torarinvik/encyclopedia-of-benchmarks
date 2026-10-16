package two_pointers_pair_exists

import "core:c"

MAX_INPUT :: 258

@(export)
two_pointers_pair_exists :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	target, n := input[0], input[1]
	if n < 0 || n > 256 || length != c.size_t(2 + n) do return -1
	if target < -2000000 || target > 2000000 do return -1
	for i in 0..<int(n) {
		value := input[2 + i]
		if value < -1000000 || value > 1000000 do return -1
		if i > 0 && input[1 + i] > value do return -1
	}
	if n < 2 do return 0
	left, right := 0, int(n) - 1
	for left < right {
		sum := input[2 + left] + input[2 + right]
		if sum == target do return 1
		if sum < target { left += 1 } else { right -= 1 }
	}
	return 0
}
