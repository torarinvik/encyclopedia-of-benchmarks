module skew_heap

const max_operations = 64
const max_live_values = 32
const max_input_length = 130
const max_output_values = 1024

struct SkewNode { value i32; left int; right int; next_free int }
struct SkewHeapState { nodes [32]SkewNode; root int; free_head int; count int }

fn initialize(mut heap SkewHeapState) {
	heap.root = -1; heap.count = 0; heap.free_head = 0
	for i in 0 .. max_live_values {
		heap.nodes[i].left = -1; heap.nodes[i].right = -1
		heap.nodes[i].next_free = if i + 1 < max_live_values { i + 1 } else { -1 }
	}
}
fn merge(mut heap SkewHeapState, first_arg int, second_arg int) int {
	if first_arg < 0 { return second_arg }
	if second_arg < 0 { return first_arg }
	mut first := first_arg; mut second := second_arg
	if heap.nodes[first].value > heap.nodes[second].value { first, second = second, first }
	old_right := heap.nodes[first].right
	heap.nodes[first].right = heap.nodes[first].left
	heap.nodes[first].left = merge(mut heap, old_right, second)
	return first
}
fn insert(mut heap SkewHeapState, value i32) bool {
	if heap.free_head < 0 { return false }
	node := heap.free_head; heap.free_head = heap.nodes[node].next_free
	heap.nodes[node] = SkewNode{value, -1, -1, -1}
	heap.root = merge(mut heap, heap.root, node); heap.count++
	return true
}
fn pop(mut heap SkewHeapState) i32 {
	node := heap.root; value := heap.nodes[node].value
	heap.root = merge(mut heap, heap.nodes[node].left, heap.nodes[node].right)
	heap.nodes[node].next_free = heap.free_head; heap.free_head = node; heap.count--
	return value
}
fn store_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> u64(8 * byte)) & 255) } }
}

@[export: 'skew_heap']
pub fn skew_heap(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > i64(max_operations) { return -1 }
		operation_count := int(input[0])
		if length != usize(1 + 2 * operation_count) || length > max_input_length - 1 { return -1 }
		mut heap := SkewHeapState{root: -1, free_head: 0, count: 0}; initialize(mut heap)
		mut answers := [max_output_values]i64{}
		mut answer_count := 0
		for operation in 0 .. operation_count {
			opcode := input[1 + 2 * operation]; argument := input[2 + 2 * operation]
			if opcode < 0 || opcode > 5 { return -1 }
			if opcode == 0 {
				if argument < -2147483648 || argument > 2147483647 || heap.count == max_live_values { return -1 }
				if !insert(mut heap, i32(argument)) { return -1 }
			} else {
				if argument != 0 { return -1 }
				if opcode == 1 {
					if heap.root < 0 { return -1 }
					answers[answer_count] = i64(heap.nodes[heap.root].value); answer_count++
				} else if opcode == 2 {
					if heap.root < 0 { return -1 }
					answers[answer_count] = i64(pop(mut heap)); answer_count++
				} else if opcode == 3 {
					mut snapshot := [max_live_values]i32{}; mut snapshot_count := 0
					for heap.root >= 0 { snapshot[snapshot_count] = pop(mut heap); snapshot_count++ }
					for i in 0 .. snapshot_count { if !insert(mut heap, snapshot[i]) { return -1 }; answers[answer_count] = i64(snapshot[i]); answer_count++ }
				} else if opcode == 4 { initialize(mut heap) }
				else { answers[answer_count] = if heap.count == 0 { 1 } else { 0 }; answer_count++ }
			}
		}
		output_bytes := answer_count * 8
		if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
		for i in 0 .. answer_count { store_i64(mut output, i * 8, answers[i]) }
		return i64(output_bytes)
	}
}
