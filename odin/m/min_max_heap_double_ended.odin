package min_max_heap_double_ended

import "core:c"

MAX_INITIAL :: 64
MAX_OPERATIONS :: 128
MAX_HEAP_SIZE :: 192
INVALID_RESULT :: i64(-1)
CAPACITY_RESULT :: i64(-2)

is_min_level :: proc "contextless" (index: int) -> bool {
	value := index + 1
	depth := 0
	for value > 1 { value >>= 1; depth += 1 }
	return depth % 2 == 0
}

swap_values :: proc "contextless" (heap: [^]i64, left, right: int) {
	temporary := heap[left]
	heap[left] = heap[right]
	heap[right] = temporary
}

best_descendant :: proc "contextless" (heap: [^]i64, count, index: int, find_min: bool) -> int {
	best := -1
	for offset := 0; offset < 6; offset += 1 {
		candidate := 0
		if offset < 2 { candidate = 2 * index + 1 + offset } else { candidate = 4 * index + 1 + offset }
		if candidate >= count do break
		if best < 0 {
			best = candidate
		} else if find_min {
			if heap[candidate] < heap[best] { best = candidate }
		} else if heap[candidate] > heap[best] { best = candidate }
	}
	return best
}

push_down :: proc "contextless" (heap: [^]i64, count, start: int, find_min: bool) {
	index := start
	for index < count {
		best := best_descendant(heap, count, index, find_min)
		if best < 0 do return
		grandchild := best > 2 && (best - 3) / 4 == index
		improves := false
		if find_min { improves = heap[best] < heap[index] } else { improves = heap[best] > heap[index] }
		if grandchild {
			if !improves do return
			swap_values(heap, best, index)
			parent := (best - 1) / 2
			violation := false
			if find_min { violation = heap[best] > heap[parent] } else { violation = heap[best] < heap[parent] }
			if violation { swap_values(heap, best, parent) }
			index = best
		} else {
			if improves { swap_values(heap, best, index) }
			return
		}
	}
}

push_up_min :: proc "contextless" (heap: [^]i64, start: int) {
	index := start
	for index > 2 {
		grandparent := (index - 3) / 4
		if heap[index] >= heap[grandparent] do return
		swap_values(heap, index, grandparent)
		index = grandparent
	}
}

push_up_max :: proc "contextless" (heap: [^]i64, start: int) {
	index := start
	for index > 2 {
		grandparent := (index - 3) / 4
		if heap[index] <= heap[grandparent] do return
		swap_values(heap, index, grandparent)
		index = grandparent
	}
}

push_up :: proc "contextless" (heap: [^]i64, index: int) {
	if index == 0 do return
	parent := (index - 1) / 2
	if is_min_level(index) {
		if heap[index] > heap[parent] {
			swap_values(heap, index, parent)
			push_up_max(heap, parent)
		} else { push_up_min(heap, index) }
	} else if heap[index] < heap[parent] {
		swap_values(heap, index, parent)
		push_up_min(heap, parent)
	} else { push_up_max(heap, index) }
}

add_value :: proc "contextless" (heap: [^]i64, count: ^int, value: i64) {
	index := count^
	count^ += 1
	heap[index] = value
	push_up(heap, index)
}

max_index :: proc "contextless" (heap: [^]i64, count: int) -> int {
	if count < 2 do return 0
	if count == 2 do return 1
	if heap[1] > heap[2] do return 1
	return 2
}

extract_at :: proc "contextless" (heap: [^]i64, count: ^int, index: int) -> i64 {
	result := heap[index]
	count^ -= 1
	if index != count^ { heap[index] = heap[count^] }
	if count^ > 0 && index < count^ { push_down(heap, count^, index, is_min_level(index)) }
	return result
}

write_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

insertion_sort :: proc "contextless" (values: [^]i64, count: int) {
	for index := 1; index < count; index += 1 {
		value := values[index]
		position := index
		for position > 0 && values[position - 1] > value { values[position] = values[position - 1]; position -= 1 }
		values[position] = value
	}
}

@(export)
min_max_heap_double_ended :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 do return INVALID_RESULT
	if input[0] < 0 || input[0] > MAX_INITIAL do return INVALID_RESULT
	initial_count := int(input[0])
	if length < c.size_t(initial_count + 2) do return INVALID_RESULT
	operation_value := input[initial_count + 1]
	if operation_value < 0 || operation_value > MAX_OPERATIONS do return INVALID_RESULT
	operation_count := int(operation_value)
	if length != c.size_t(initial_count + 2 + 2 * operation_count) do return INVALID_RESULT
	for index := 0; index < initial_count; index += 1 {
		if input[index + 1] < -2_147_483_648 || input[index + 1] > 2_147_483_647 do return INVALID_RESULT
	}
	for op := 0; op < operation_count; op += 1 {
		opcode := input[initial_count + 2 + 2 * op]
		argument := input[initial_count + 3 + 2 * op]
		if opcode < 0 || opcode > 5 do return INVALID_RESULT
		if opcode == 0 { if argument < -2_147_483_648 || argument > 2_147_483_647 do return INVALID_RESULT }
		else if argument != 0 do return INVALID_RESULT
	}

	heap: [MAX_HEAP_SIZE]i64
	count := initial_count
	for index := 0; index < initial_count; index += 1 { heap[index] = input[index + 1] }
	for index := initial_count / 2; index > 0; index -= 1 { push_down(&heap[0], count, index - 1, is_min_level(index - 1)) }
	events: [MAX_OPERATIONS]i64
	event_count := 0
	for op := 0; op < operation_count; op += 1 {
		opcode := input[initial_count + 2 + 2 * op]
		argument := input[initial_count + 3 + 2 * op]
		if opcode == 0 { add_value(&heap[0], &count, argument) }
		else if opcode == 1 || opcode == 3 {
			if count == 0 do return INVALID_RESULT
			if opcode == 1 { events[event_count] = heap[0] } else { events[event_count] = extract_at(&heap[0], &count, 0) }
			event_count += 1
		} else if opcode == 2 || opcode == 4 {
			if count == 0 do return INVALID_RESULT
			index := max_index(&heap[0], count)
			if opcode == 2 { events[event_count] = heap[index] } else { events[event_count] = extract_at(&heap[0], &count, index) }
			event_count += 1
		} else { events[event_count] = i64(count); event_count += 1 }
	}
	sorted: [MAX_HEAP_SIZE]i64
	for index := 0; index < count; index += 1 { sorted[index] = heap[index] }
	insertion_sort(&sorted[0], count)
	required := (2 + event_count + count) * 8
	if output == nil || capacity < c.size_t(required) do return CAPACITY_RESULT
	offset := 0
	write_i64_le(output, offset, i64(event_count)); offset += 8
	for index := 0; index < event_count; index += 1 { write_i64_le(output, offset, events[index]); offset += 8 }
	write_i64_le(output, offset, i64(count)); offset += 8
	for index := 0; index < count; index += 1 { write_i64_le(output, offset, sorted[index]); offset += 8 }
	return i64(required)
}
