package merge_ksorted_arrays

MAX_ARRAYS :: 16
MAX_TOTAL_VALUES :: 128
MAX_PARSEABLE_LENGTH :: 146
MIN_VALUE :: i64(-1_000_000)
MAX_VALUE :: i64(1_000_000)
CHECKSUM_OFFSET :: i64(1_000_001)

Heap_Node :: struct {
	value: i64,
	array_index: int,
	element_index: int,
}
Heap :: [MAX_ARRAYS]Heap_Node

node_less :: proc "contextless" (left, right: Heap_Node) -> bool {
	if left.value != right.value do return left.value < right.value
	if left.array_index != right.array_index do return left.array_index < right.array_index
	return left.element_index < right.element_index
}

heap_push :: proc "contextless" (heap: ^Heap, size: ^int, node: Heap_Node) {
	index := size^
	size^ += 1
	for index > 0 {
		parent := (index - 1) / 2
		if !node_less(node, heap^[parent]) do break
		heap^[index] = heap^[parent]
		index = parent
	}
	heap^[index] = node
}

heap_pop :: proc "contextless" (heap: ^Heap, size: ^int) -> Heap_Node {
	result := heap^[0]
	size^ -= 1
	last := heap^[size^]
	if size^ > 0 {
		index := 0
		for index < size^ / 2 {
			child := 2 * index + 1
			if child + 1 < size^ && node_less(heap^[child + 1], heap^[child]) do child += 1
			if !node_less(heap^[child], last) do break
			heap^[index] = heap^[child]
			index = child
		}
		heap^[index] = last
	}
	return result
}

@(export)
merge_ksorted_arrays :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > MAX_PARSEABLE_LENGTH do return -1
	if values[0] < 1 || values[0] > MAX_ARRAYS do return -1
	array_count := int(values[0])
	starts: [MAX_ARRAYS]int
	lengths: [MAX_ARRAYS]int
	position := 1
	total_values := 0
	for array_index := 0; array_index < array_count; array_index += 1 {
		if position >= int(length) do return -1
		declared := values[position]
		position += 1
		if declared < 0 || declared > i64(MAX_TOTAL_VALUES - total_values) do return -1
		array_length := int(declared)
		if array_length > int(length) - position do return -1
		starts[array_index] = position
		lengths[array_index] = array_length
		for index := 0; index < array_length; index += 1 {
			value := values[position + index]
			if value < MIN_VALUE || value > MAX_VALUE ||
				(index > 0 && values[position + index - 1] > value) do return -1
		}
		position += array_length
		total_values += array_length
	}
	if position != int(length) do return -1

	var heap: Heap
	heap_size := 0
	for array_index := 0; array_index < array_count; array_index += 1 {
		if lengths[array_index] > 0 {
			heap_push(&heap, &heap_size, Heap_Node{values[starts[array_index]], array_index, 0})
		}
	}
	checksum := i64(0)
	merged_index := i64(0)
	for heap_size > 0 {
		node := heap_pop(&heap, &heap_size)
		checksum += (merged_index + 1) * (node.value + CHECKSUM_OFFSET)
		merged_index += 1
		next_index := node.element_index + 1
		if next_index < lengths[node.array_index] {
			heap_push(&heap, &heap_size, Heap_Node{values[starts[node.array_index] + next_index], node.array_index, next_index})
		}
	}
	return checksum
}
