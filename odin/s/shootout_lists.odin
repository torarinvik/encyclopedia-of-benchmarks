package shootout_lists

import "core:c"

LIST_SIZE :: 100
MIN_RUNS :: i64(0)
MAX_RUNS :: i64(10000)
NODE_COUNT :: 203

ListNode :: struct { value: i32, next: int, prev: int }

init_sequence :: proc(nodes: [^]ListNode, head, base: int) {
	nodes[head].value = i32(LIST_SIZE)
	nodes[head].next = base
	nodes[head].prev = base + LIST_SIZE - 1
	for offset in 0..<LIST_SIZE {
		item := base + offset
		nodes[item].value = i32(offset + 1)
		nodes[item].prev = if offset == 0 { head } else { item - 1 }
		nodes[item].next = if offset + 1 == LIST_SIZE { head } else { item + 1 }
	}
}

list_length :: proc(nodes: [^]ListNode, head: int) -> i32 { return nodes[head].value }

pop_head :: proc(nodes: [^]ListNode, head: int) -> int {
	if list_length(nodes, head) == 0 do return -1
	item := nodes[head].next
	next := nodes[item].next
	nodes[head].next = next
	nodes[next].prev = head
	nodes[head].value -= 1
	return item
}

pop_tail :: proc(nodes: [^]ListNode, head: int) -> int {
	if list_length(nodes, head) == 0 do return -1
	item := nodes[head].prev
	prev := nodes[item].prev
	nodes[head].prev = prev
	nodes[prev].next = head
	nodes[head].value -= 1
	return item
}

push_tail :: proc(nodes: [^]ListNode, head, item: int) {
	tail := nodes[head].prev
	nodes[tail].next = item
	nodes[item].next = head
	nodes[head].prev = item
	nodes[item].prev = tail
	nodes[head].value += 1
}

reverse_list :: proc(nodes: [^]ListNode, head: int) {
	current := head
	for {
		old_next := nodes[current].next
		nodes[current].next = nodes[current].prev
		nodes[current].prev = old_next
		current = old_next
		if current == head do break
	}
}

lists_equal :: proc(nodes: [^]ListNode, left, right: int) -> bool {
	if list_length(nodes, left) != list_length(nodes, right) do return false
	a, b := nodes[left].next, nodes[right].next
	for a != left && b != right {
		if nodes[a].value != nodes[b].value do return false
		a = nodes[a].next
		b = nodes[b].next
	}
	return a == left && b == right
}

test_lists :: proc() -> bool {
	var nodes: [NODE_COUNT]ListNode
	original, copied, staging := 0, 101, 202
	init_sequence(&nodes[0], original, 1)
	init_sequence(&nodes[0], copied, 102)
	nodes[staging] = ListNode{value = 0, next = staging, prev = staging}
	if !lists_equal(&nodes[0], copied, original) do return false
	for list_length(&nodes[0], copied) > 0 {
		item := pop_head(&nodes[0], copied)
		if item < 0 do return false
		push_tail(&nodes[0], staging, item)
	}
	if list_length(&nodes[0], copied) != 0 do return false
	for list_length(&nodes[0], staging) > 0 {
		item := pop_tail(&nodes[0], staging)
		if item < 0 do return false
		push_tail(&nodes[0], copied, item)
	}
	if list_length(&nodes[0], staging) != 0 do return false
	reverse_list(&nodes[0], original)
	return nodes[nodes[original].next].value == i32(LIST_SIZE) &&
		nodes[nodes[original].prev].value == 1 &&
		nodes[nodes[copied].next].value == i32(LIST_SIZE) &&
		nodes[nodes[copied].prev].value == 1 &&
		list_length(&nodes[0], original) == i32(LIST_SIZE) &&
		lists_equal(&nodes[0], original, copied)
}

@(export)
shootout_lists :: proc "c" (runs: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if runs < MIN_RUNS || runs > MAX_RUNS do return -1
	if output == nil do return -2
	staged: [4]u8
	output_bytes := 4
	if runs == 0 { staged[0] = '0'; staged[1] = '\n'; output_bytes = 2 }
	else { staged[0] = '1'; staged[1] = '0'; staged[2] = '0'; staged[3] = '\n' }
	if output_capacity < c.size_t(output_bytes) do return -2
	for _ in 0..<int(runs) { if !test_lists() do return -1 }
	for index in 0..<output_bytes { output[index] = staged[index] }
	return i64(output_bytes)
}
