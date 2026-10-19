const list_size = 100
const min_runs = i64(0)
const max_runs = i64(10000)
const node_count = 203

struct ListNode {
	value i32
	next int
	prev int
}

fn init_sequence(mut nodes []ListNode, head int, base int) {
	nodes[head].value = i32(list_size)
	nodes[head].next = base
	nodes[head].prev = base + list_size - 1
	for offset in 0 .. list_size {
		item := base + offset
		nodes[item].value = i32(offset + 1)
		nodes[item].prev = if offset == 0 { head } else { item - 1 }
		nodes[item].next = if offset + 1 == list_size { head } else { item + 1 }
	}
}

fn list_length(nodes []ListNode, head int) i32 { return nodes[head].value }

fn pop_head(mut nodes []ListNode, head int) int {
	if list_length(nodes, head) == 0 { return -1 }
	item := nodes[head].next
	next := nodes[item].next
	nodes[head].next = next
	nodes[next].prev = head
	nodes[head].value--
	return item
}

fn pop_tail(mut nodes []ListNode, head int) int {
	if list_length(nodes, head) == 0 { return -1 }
	item := nodes[head].prev
	prev := nodes[item].prev
	nodes[head].prev = prev
	nodes[prev].next = head
	nodes[head].value--
	return item
}

fn push_tail(mut nodes []ListNode, head int, item int) {
	tail := nodes[head].prev
	nodes[tail].next = item
	nodes[item].next = head
	nodes[head].prev = item
	nodes[item].prev = tail
	nodes[head].value++
}

fn reverse_list(mut nodes []ListNode, head int) {
	mut current := head
	for {
		old_next := nodes[current].next
		nodes[current].next = nodes[current].prev
		nodes[current].prev = old_next
		current = old_next
		if current == head { break }
	}
}

fn lists_equal(nodes []ListNode, left int, right int) bool {
	if list_length(nodes, left) != list_length(nodes, right) { return false }
	mut a := nodes[left].next
	mut b := nodes[right].next
	for a != left && b != right {
		if nodes[a].value != nodes[b].value { return false }
		a = nodes[a].next
		b = nodes[b].next
	}
	return a == left && b == right
}

fn test_lists() bool {
	mut nodes := [node_count]ListNode{}
	original := 0
	copied := 101
	staging := 202
	init_sequence(mut nodes[..], original, 1)
	init_sequence(mut nodes[..], copied, 102)
	nodes[staging] = ListNode{value: 0, next: staging, prev: staging}
	if !lists_equal(nodes[..], copied, original) { return false }
	for list_length(nodes[..], copied) > 0 {
		item := pop_head(mut nodes[..], copied)
		if item < 0 { return false }
		push_tail(mut nodes[..], staging, item)
	}
	if list_length(nodes[..], copied) != 0 { return false }
	for list_length(nodes[..], staging) > 0 {
		item := pop_tail(mut nodes[..], staging)
		if item < 0 { return false }
		push_tail(mut nodes[..], copied, item)
	}
	if list_length(nodes[..], staging) != 0 { return false }
	reverse_list(mut nodes[..], original)
	return nodes[nodes[original].next].value == i32(list_size) &&
		nodes[nodes[original].prev].value == 1 &&
		nodes[nodes[copied].next].value == i32(list_size) &&
		nodes[nodes[copied].prev].value == 1 &&
		list_length(nodes[..], original) == i32(list_size) &&
		lists_equal(nodes[..], original, copied)
}

@[export: 'shootout_lists']
pub fn shootout_lists(runs i64, mut output &u8, output_capacity usize) i64 {
	if runs < min_runs || runs > max_runs { return -1 }
	if unsafe { output == nil } { return -2 }
	mut staged := [4]u8{}
	output_bytes := if runs == 0 { 2 } else { 4 }
	if runs == 0 { staged[0] = `0`; staged[1] = `\n` }
	else { staged[0] = `1`; staged[1] = `0`; staged[2] = `0`; staged[3] = `\n` }
	if output_capacity < usize(output_bytes) { return -2 }
	for _ in 0 .. int(runs) { if !test_lists() { return -1 } }
	unsafe { for index in 0 .. output_bytes { output[index] = staged[index] } }
	return i64(output_bytes)
}
