package maximum_unique_subarray

import "core:c"

// Maximize the sum of a contiguous window with distinct values.
@(export)
maximum_unique_subarray :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 256 do return -1
	keys: [512]i64 = {}
	last_seen: [512]int = {}
	occupied: [512]bool = {}
	left := 0
	window_sum := i64(0)
	best := i64(0)
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < 1 || value > 10_000 do return -1
		slot := int(value % 512)
		for occupied[slot] && keys[slot] != value { slot = (slot + 1) % 512 }
		previous := last_seen[slot]
		for left < previous {
			window_sum -= values[left]
			left += 1
		}
		window_sum += value
		keys[slot] = value
		last_seen[slot] = index + 1
		occupied[slot] = true
		if window_sum > best do best = window_sum
	}
	return best
}
