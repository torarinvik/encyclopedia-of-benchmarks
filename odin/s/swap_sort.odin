package swap_sort

import "core:c"

position_less :: proc "contextless" (keys: [^]i64, order: [^]int, left, right: int) -> bool {
	a, b := order[left], order[right]
	return keys[a] < keys[b] || (keys[a] == keys[b] && a < b)
}

sift_down :: proc "contextless" (keys: [^]i64, order: [^]int, heap_length, root_value: int) {
	root := root_value
	for root < heap_length / 2 {
		child := root * 2 + 1
		if child + 1 < heap_length && position_less(keys, order, child, child + 1) do child += 1
		if !position_less(keys, order, root, child) do break
		temporary := order[root]; order[root] = order[child]; order[child] = temporary
		root = child
	}
}

@(export)
swap_sort :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 256 do return -1
	n := int(length)
	keys: [256]i64
	order: [256]int
	visited: [256]bool
	for index := 0; index < n; index += 1 { keys[index] = values[index]; order[index] = index }
	for start := n / 2; start > 0; {
		start -= 1
		sift_down(&keys[0], &order[0], n, start)
	}
	for finish := n; finish > 1; {
		finish -= 1
		temporary := order[0]; order[0] = order[finish]; order[finish] = temporary
		sift_down(&keys[0], &order[0], finish, 0)
	}
	for index := 1; index < n; index += 1 {
		if keys[order[index - 1]] == keys[order[index]] do return -1
	}
	swaps := 0
	for first := 0; first < n; first += 1 {
		if visited[first] do continue
		node := first
		cycle_length := 0
		for !visited[node] { visited[node] = true; node = order[node]; cycle_length += 1 }
		if cycle_length > 0 do swaps += cycle_length - 1
	}
	return i64(swaps)
}
