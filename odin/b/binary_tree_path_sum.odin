package binary_tree_path_sum

import "core:c"

MAX_NODES :: 63

count_from :: proc "contextless" (input: [^]i64, node: int, sum, target: i64) -> i64 {
	base := 2 + 3 * node
	count := i64(0)
	if sum == target do count = 1
	left, right := input[base + 1], input[base + 2]
	if left >= 0 do count += count_from(input, int(left), sum + input[2 + 3 * int(left)], target)
	if right >= 0 do count += count_from(input, int(right), sum + input[2 + 3 * int(right)], target)
	return count
}

start_at_each_node :: proc "contextless" (input: [^]i64, node: int) -> i64 {
	base := 2 + 3 * node
	count := count_from(input, node, input[base], input[0])
	left, right := input[base + 1], input[base + 2]
	if left >= 0 do count += start_at_each_node(input, int(left))
	if right >= 0 do count += start_at_each_node(input, int(right))
	return count
}

@(export)
binary_tree_path_sum :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || input[1] < 0 || input[1] > MAX_NODES do return -1
	count := int(input[1])
	if int(length) != 2 + 3 * count do return -1
	if count == 0 do return 0
	parents: [MAX_NODES]int
	for node := 0; node < count; node += 1 {
		base := 2 + 3 * node
		if input[base] < i64(-2147483648) || input[base] > i64(2147483647) do return -1
		for side := 1; side <= 2; side += 1 {
			child := input[base + side]
			if child < -1 || child >= i64(count) do return -1
			if child >= 0 {
				parents[int(child)] += 1
				if parents[int(child)] > 1 do return -1
			}
		}
	}
	if parents[0] != 0 do return -1
	for node := 1; node < count; node += 1 do if parents[node] != 1 do return -1
	seen: [MAX_NODES]bool
	stack: [MAX_NODES]int
	top, reached := 0, 0
	stack[top] = 0; top += 1
	for top > 0 {
		top -= 1
		node := stack[top]
		if seen[node] do return -1
		seen[node] = true; reached += 1
		base := 2 + 3 * node
		if input[base + 1] >= 0 { stack[top] = int(input[base + 1]); top += 1 }
		if input[base + 2] >= 0 { stack[top] = int(input[base + 2]); top += 1 }
	}
	if reached != count do return -1
	return start_at_each_node(input, 0)
}
