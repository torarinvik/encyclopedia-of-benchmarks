package knapsack_recursive

import "core:c"

MAX_CAPACITY :: i64(512)
MAX_ITEMS :: i64(16)
MAX_WEIGHT :: i64(4096)
MAX_VALUE :: i64(1_000_000_000)

solve :: proc "contextless" (packed: [^]i64, item_count, capacity: i64) -> i64 {
	if item_count == 0 || capacity == 0 do return 0
	offset := int(2 + 2 * (item_count - 1))
	weight := packed[offset]
	value := packed[offset + 1]
	if weight <= capacity {
		take := value + solve(packed, item_count - 1, capacity - weight)
		skip := solve(packed, item_count - 1, capacity)
		if take > skip do return take
		return skip
	}
	return solve(packed, item_count - 1, capacity)
}

@(export)
knapsack_01_recursive_benchmark :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if length < 2 || length > 34 do return -1
	capacity := packed[0]
	item_count := packed[1]
	if capacity < 0 || capacity > MAX_CAPACITY || item_count < 0 || item_count > MAX_ITEMS || int(length) != 2 + 2 * int(item_count) do return -1
	for item := 0; item < int(item_count); item += 1 {
		offset := 2 + 2 * item
		if packed[offset] < 1 || packed[offset] > MAX_WEIGHT || packed[offset + 1] < 0 || packed[offset + 1] > MAX_VALUE do return -1
	}
	return solve(packed, item_count, capacity)
}
