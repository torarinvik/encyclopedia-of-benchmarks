package interval_heap_double_ended

import "core:c"

MAX_INITIAL :: 64
MAX_OPERATIONS :: 128
MAX_KEYS :: MAX_INITIAL + MAX_OPERATIONS
MAX_INPUT :: MAX_INITIAL + 2 + 2 * MAX_OPERATIONS

IntervalHeap :: struct {
	keys: [MAX_KEYS]i32,
	count: int,
}

high_index :: proc "contextless" (heap: ^IntervalHeap, node: int) -> int {
	high := 2 * node + 1
	if high < heap.count do return high
	return 2 * node
}

sift_up_low :: proc "contextless" (heap: ^IntervalHeap, start: int) {
	node := start
	for node > 0 {
		parent := (node - 1) / 2
		low := 2 * node
		parent_low := 2 * parent
		if heap.keys[low] >= heap.keys[parent_low] do return
		temporary := heap.keys[low]
		heap.keys[low] = heap.keys[parent_low]
		heap.keys[parent_low] = temporary
		node = parent
	}
}

sift_up_high :: proc "contextless" (heap: ^IntervalHeap, start: int) {
	node := start
	for node > 0 {
		parent := (node - 1) / 2
		high := high_index(heap, node)
		parent_high := high_index(heap, parent)
		if heap.keys[high] <= heap.keys[parent_high] do return
		temporary := heap.keys[high]
		heap.keys[high] = heap.keys[parent_high]
		heap.keys[parent_high] = temporary
		node = parent
	}
}

insert_key :: proc "contextless" (heap: ^IntervalHeap, value: i32) {
	key_index := heap.count
	heap.keys[key_index] = value
	heap.count += 1
	node := key_index / 2
	if key_index % 2 == 1 && heap.keys[key_index] < heap.keys[key_index - 1] {
		temporary := heap.keys[key_index]
		heap.keys[key_index] = heap.keys[key_index - 1]
		heap.keys[key_index - 1] = temporary
	}
	sift_up_low(heap, node)
	sift_up_high(heap, node)
}

extract_min :: proc "contextless" (heap: ^IntervalHeap) -> i32 {
	result := heap.keys[0]
	heap.count -= 1
	last := heap.keys[heap.count]
	if heap.count == 0 do return result
	heap.keys[0] = last
	node := 0
	for {
		left := 2 * node + 1
		if 2 * left >= heap.count do return result
		right := left + 1
		child := left
		if 2 * right < heap.count && heap.keys[2 * right] < heap.keys[2 * left] { child = right }
		node_low := 2 * node
		child_low := 2 * child
		if heap.keys[child_low] >= heap.keys[node_low] do return result
		temporary := heap.keys[node_low]
		heap.keys[node_low] = heap.keys[child_low]
		heap.keys[child_low] = temporary
		child_high := high_index(heap, child)
		if heap.keys[child_high] < heap.keys[child_low] {
			pair_temporary := heap.keys[child_high]
			heap.keys[child_high] = heap.keys[child_low]
			heap.keys[child_low] = pair_temporary
		}
		node = child
	}
}

extract_max :: proc "contextless" (heap: ^IntervalHeap) -> i32 {
	if heap.count <= 2 {
		heap.count -= 1
		return heap.keys[heap.count]
	}
	result := heap.keys[1]
	heap.count -= 1
	heap.keys[1] = heap.keys[heap.count]
	node := 0
	for {
		left := 2 * node + 1
		if 2 * left >= heap.count do return result
		right := left + 1
		child := left
		if 2 * right < heap.count && heap.keys[high_index(heap, left)] < heap.keys[high_index(heap, right)] { child = right }
		node_high := high_index(heap, node)
		child_high := high_index(heap, child)
		if heap.keys[node_high] >= heap.keys[child_high] do return result
		temporary := heap.keys[node_high]
		heap.keys[node_high] = heap.keys[child_high]
		heap.keys[child_high] = temporary
		child_low := 2 * child
		if heap.keys[child_high] < heap.keys[child_low] {
			pair_temporary := heap.keys[child_high]
			heap.keys[child_high] = heap.keys[child_low]
			heap.keys[child_low] = pair_temporary
		}
		node = child
	}
}

write_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

sort_i32 :: proc "contextless" (values: ^[MAX_KEYS]i32, count: int) {
	for index := 1; index < count; index += 1 {
		value := values[index]
		position := index
		for position > 0 && values[position - 1] > value { values[position] = values[position - 1]; position -= 1 }
		values[position] = value
	}
}

@(export)
interval_heap_double_ended :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	if input[0] < 0 || input[0] > MAX_INITIAL do return -1
	initial_count := int(input[0])
	if length < c.size_t(initial_count + 2) || input[initial_count + 1] < 0 || input[initial_count + 1] > MAX_OPERATIONS do return -1
	operation_count := int(input[initial_count + 1])
	if length != c.size_t(initial_count + 2 + 2 * operation_count) do return -1
	for index := 0; index < initial_count; index += 1 {
		if input[index + 1] < -2_147_483_648 || input[index + 1] > 2_147_483_647 do return -1
	}
	for op := 0; op < operation_count; op += 1 {
		opcode := input[initial_count + 2 + 2 * op]
		argument := input[initial_count + 3 + 2 * op]
		if opcode < 0 || opcode > 5 do return -1
		if opcode == 0 { if argument < -2_147_483_648 || argument > 2_147_483_647 do return -1 }
		else if argument != 0 do return -1
	}

	var heap: IntervalHeap
	for index := 0; index < initial_count; index += 1 { insert_key(&heap, i32(input[index + 1])) }
	events: [MAX_OPERATIONS]i64
	event_count := 0
	for op := 0; op < operation_count; op += 1 {
		opcode := input[initial_count + 2 + 2 * op]
		argument := i32(input[initial_count + 3 + 2 * op])
		if opcode == 0 { insert_key(&heap, argument) }
		else if opcode == 1 { if heap.count == 0 do return -1; events[event_count] = i64(heap.keys[0]); event_count += 1 }
		else if opcode == 2 { if heap.count == 0 do return -1; events[event_count] = i64(heap.keys[high_index(&heap, 0)]); event_count += 1 }
		else if opcode == 3 { if heap.count == 0 do return -1; events[event_count] = i64(extract_min(&heap)); event_count += 1 }
		else if opcode == 4 { if heap.count == 0 do return -1; events[event_count] = i64(extract_max(&heap)); event_count += 1 }
		else { events[event_count] = i64(heap.count); event_count += 1 }
	}
	var sorted: [MAX_KEYS]i32
	for index := 0; index < heap.count; index += 1 { sorted[index] = heap.keys[index] }
	sort_i32(&sorted, heap.count)
	required := (2 + event_count + heap.count) * 8
	if output == nil || capacity < c.size_t(required) do return -2
	offset := 0
	write_i64_le(output, offset, i64(event_count)); offset += 8
	for index := 0; index < event_count; index += 1 { write_i64_le(output, offset, events[index]); offset += 8 }
	write_i64_le(output, offset, i64(heap.count)); offset += 8
	for index := 0; index < heap.count; index += 1 { write_i64_le(output, offset, i64(sorted[index])); offset += 8 }
	return i64(required)
}
