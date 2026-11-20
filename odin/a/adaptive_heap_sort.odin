package adaptive_heap_sort

import "core:c"

MAX_VALUES :: 1024

node_less :: proc(values: [^]i64, left, right: c.size_t) -> bool {
	return values[left] < values[right] || (values[left] == values[right] && left < right)
}

push_candidate :: proc(values: [^]i64, heap: [^]c.size_t, heap_length: ^c.size_t, node: c.size_t) {
	position := heap_length^
	heap_length^ += 1
	heap[position] = node
	for position > 0 {
		parent := (position - 1) / 2
		if !node_less(values, heap[position], heap[parent]) { break }
		temporary := heap[position]
		heap[position] = heap[parent]
		heap[parent] = temporary
		position = parent
	}
}

pop_candidate :: proc(values: [^]i64, heap: [^]c.size_t, heap_length: ^c.size_t) -> c.size_t {
	minimum := heap[0]
	heap_length^ -= 1
	if heap_length^ == 0 { return minimum }
	heap[0] = heap[heap_length^]
	position := c.size_t(0)
	for position < heap_length^ / 2 {
		child := position * 2 + 1
		if child + 1 < heap_length^ && node_less(values, heap[child + 1], heap[child]) { child += 1 }
		if !node_less(values, heap[child], heap[position]) { break }
		temporary := heap[position]
		heap[position] = heap[child]
		heap[child] = temporary
		position = child
	}
	return minimum
}

@(export)
adaptive_heap_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if values == nil || length < 2 || length > MAX_VALUES { return }
	left: [MAX_VALUES]c.size_t
	right: [MAX_VALUES]c.size_t
	construction_stack: [MAX_VALUES]c.size_t
	candidate_heap: [MAX_VALUES]c.size_t
	output: [MAX_VALUES]i64

	stack_length := c.size_t(0)
	for index := c.size_t(0); index < length; index += 1 {
		left[index] = length
		right[index] = length
		last := length
		for stack_length > 0 && values[construction_stack[stack_length - 1]] > values[index] {
			stack_length -= 1
			last = construction_stack[stack_length]
		}
		if stack_length > 0 { right[construction_stack[stack_length - 1]] = index }
		if last < length { left[index] = last }
		construction_stack[stack_length] = index
		stack_length += 1
	}

	heap_length := c.size_t(0)
	push_candidate(values, &candidate_heap[0], &heap_length, construction_stack[0])
	for output_index := c.size_t(0); output_index < length; output_index += 1 {
		node := pop_candidate(values, &candidate_heap[0], &heap_length)
		output[output_index] = values[node]
		if left[node] < length { push_candidate(values, &candidate_heap[0], &heap_length, left[node]) }
		if right[node] < length { push_candidate(values, &candidate_heap[0], &heap_length, right[node]) }
	}
	for index := c.size_t(0); index < length; index += 1 { values[index] = output[index] }
}
