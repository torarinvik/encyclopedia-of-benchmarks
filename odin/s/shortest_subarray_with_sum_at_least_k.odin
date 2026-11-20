package shortest_subarray_with_sum_at_least_k

import "core:c"

MAX_COUNT :: 256
MAX_INPUT :: 259

@(export)
shortest_subarray_with_sum_at_least_k :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 2 || length > MAX_INPUT do return -1
	target, count := packed[0], packed[1]
	if target < -4096 || target > 4096 || count < 0 || count > MAX_COUNT do return -1
	if length != c.size_t(count) + 2 do return -1
	n := int(count)

	prefix: [MAX_COUNT+1]i64
	for index := 0; index < n; index += 1 {
		value := packed[index+2]
		if value < -1000 || value > 1000 do return -1
		prefix[index+1] = prefix[index] + value
	}

	deque: [MAX_COUNT+1]int
	head, tail := 0, 0
	best := n + 1
	for right := 0; right <= n; right += 1 {
		for head < tail && prefix[right]-prefix[deque[head]] >= target {
			width := right-deque[head]
			if width < best do best = width
			head += 1
		}
		for head < tail && prefix[right] <= prefix[deque[tail-1]] {
			tail -= 1
		}
		deque[tail] = right
		tail += 1
	}
	if best <= n do return i64(best)
	return 0
}

