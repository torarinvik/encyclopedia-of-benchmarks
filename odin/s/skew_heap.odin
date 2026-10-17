package skew_heap

import "core:c"

MAX_OPERATIONS :: 64
MAX_LIVE_VALUES :: 32
MAX_INPUT_LENGTH :: 130
MAX_OUTPUT_VALUES :: 1024
Skew_Node :: struct { value: i32, left: int, right: int, next_free: int }
Skew_Heap :: struct { nodes: [MAX_LIVE_VALUES]Skew_Node, root: int, free_head: int, count: int }

initialize :: proc "contextless" (heap: ^Skew_Heap) {
	heap.root = -1; heap.count = 0; heap.free_head = 0
	for i := 0; i < MAX_LIVE_VALUES; i += 1 {
		heap.nodes[i].left = -1; heap.nodes[i].right = -1
		heap.nodes[i].next_free = if i + 1 < MAX_LIVE_VALUES do i + 1 else -1
	}
}
merge :: proc "contextless" (heap: ^Skew_Heap, first_arg, second_arg: int) -> int {
	if first_arg < 0 do return second_arg
	if second_arg < 0 do return first_arg
	first, second := first_arg, second_arg
	if heap.nodes[first].value > heap.nodes[second].value { first, second = second, first }
	old_right := heap.nodes[first].right
	heap.nodes[first].right = heap.nodes[first].left
	heap.nodes[first].left = merge(heap, old_right, second)
	return first
}
insert :: proc "contextless" (heap: ^Skew_Heap, value: i32) -> bool {
	if heap.free_head < 0 do return false
	node := heap.free_head; heap.free_head = heap.nodes[node].next_free
	heap.nodes[node] = Skew_Node{value, -1, -1, -1}
	heap.root = merge(heap, heap.root, node); heap.count += 1
	return true
}
pop :: proc "contextless" (heap: ^Skew_Heap) -> i32 {
	node := heap.root; value := heap.nodes[node].value
	heap.root = merge(heap, heap.nodes[node].left, heap.nodes[node].right)
	heap.nodes[node].next_free = heap.free_head; heap.free_head = node; heap.count -= 1
	return value
}
store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u32(8*byte)) }
}

@(export)
skew_heap :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_OPERATIONS do return -1
	operation_count := int(input[0])
	if int(length) != 1 + 2*operation_count || length > MAX_INPUT_LENGTH-1 do return -1
	mut heap: Skew_Heap; initialize(&heap)
	answers: [MAX_OUTPUT_VALUES]i64; answer_count := 0
	for operation := 0; operation < operation_count; operation += 1 {
		opcode, argument := input[1+2*operation], input[2+2*operation]
		if opcode < 0 || opcode > 5 do return -1
		if opcode == 0 {
			if argument < -2147483648 || argument > 2147483647 || heap.count == MAX_LIVE_VALUES do return -1
			if !insert(&heap, i32(argument)) do return -1
		} else {
			if argument != 0 do return -1
			if opcode == 1 { if heap.root < 0 do return -1; answers[answer_count] = i64(heap.nodes[heap.root].value); answer_count += 1 }
			else if opcode == 2 { if heap.root < 0 do return -1; answers[answer_count] = i64(pop(&heap)); answer_count += 1 }
			else if opcode == 3 {
				snapshot: [MAX_LIVE_VALUES]i32; snapshot_count := 0
				for heap.root >= 0 { snapshot[snapshot_count] = pop(&heap); snapshot_count += 1 }
				for i := 0; i < snapshot_count; i += 1 { if !insert(&heap, snapshot[i]) do return -1; answers[answer_count] = i64(snapshot[i]); answer_count += 1 }
			} else if opcode == 4 { initialize(&heap) }
			else { answers[answer_count] = if heap.count == 0 do 1 else 0; answer_count += 1 }
		}
	}
	output_bytes := answer_count * 8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for i := 0; i < answer_count; i += 1 { store_i64_le(output, i*8, answers[i]) }
	return i64(output_bytes)
}
