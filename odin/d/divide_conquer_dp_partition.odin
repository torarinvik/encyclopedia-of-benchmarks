package divide_conquer_dp_partition

import "core:c"

MAX_N :: 64
MAX_GROUPS :: 8
MAX_INPUT :: 66
STACK_CAPACITY :: 136
INF :: i64(0x1fffffffffffffff)
Task :: struct { left, right, low, high: int }

compute_row :: proc(previous, current: [^]i64, prefix: [^]i64, n, group: int) {
	stack: [STACK_CAPACITY]Task
	top := 1
	stack[0] = {group, n, group - 1, n - 1}
	for top > 0 {
		top -= 1
		task := stack[top]
		if task.left > task.right do continue
		middle := task.left + (task.right - task.left) / 2
		upper := min(task.high, middle - 1)
		best := INF
		best_split := task.low
		for split := task.low; split <= upper; split += 1 {
			if previous[split] == INF do continue
			segment := prefix[middle] - prefix[split]
			candidate := previous[split] + segment * segment
			if candidate < best { best = candidate; best_split = split }
		}
		current[middle] = best
		if middle < task.right {
			stack[top] = {middle + 1, task.right, best_split, task.high}
			top += 1
		}
		if task.left < middle {
			stack[top] = {task.left, middle - 1, task.low, best_split}
			top += 1
		}
	}
}

@(export)
divide_conquer_dp_partition :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 3 || length > MAX_INPUT do return -1
	n_value, groups_value := values[0], values[1]
	if n_value < 1 || n_value > MAX_N || groups_value < 1 || groups_value > MAX_GROUPS ||
		groups_value > n_value || int(length) != int(n_value) + 2 do return -1
	n, groups := int(n_value), int(groups_value)
	prefix: [MAX_N + 1]i64 = {}
	first, second: [MAX_N + 1]i64
	for i := 0; i < n; i += 1 {
		value := values[i + 2]
		if value < 0 || value > 1000 do return -1
		prefix[i + 1] = prefix[i] + value
	}
	for i := 0; i <= n; i += 1 { first[i] = INF }
	first[0] = 0
	previous := &first[0]
	current := &second[0]
	for group := 1; group <= groups; group += 1 {
		for i := 0; i <= n; i += 1 { current[i] = INF }
		compute_row(previous, current, &prefix[0], n, group)
		temporary := previous; previous = current; current = temporary
	}
	return previous[n]
}
