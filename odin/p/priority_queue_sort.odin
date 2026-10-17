package priority_queue_sort

import "core:c"

MAX_COUNT :: 128
MAX_PARSEABLE_INPUT_LENGTH :: 130

heap_push :: proc "contextless" (heap: [^]i32, size: ^int, value: i32) {
	child := size^
	size^ += 1
	heap[child] = value
	for child > 0 {
		parent := (child - 1) / 2
		if heap[parent] <= heap[child] do break
		temporary := heap[parent]
		heap[parent] = heap[child]
		heap[child] = temporary
		child = parent
	}
}

heap_pop :: proc "contextless" (heap: [^]i32, size: ^int) -> i32 {
	minimum := heap[0]
	size^ -= 1
	if size^ == 0 do return minimum
	heap[0] = heap[size^]
	parent := 0
	for {
		left := 2 * parent + 1
		if left >= size^ do break
		right := left + 1
		smaller := left
		if right < size^ && heap[right] < heap[left] do smaller = right
		if heap[parent] <= heap[smaller] do break
		temporary := heap[parent]
		heap[parent] = heap[smaller]
		heap[smaller] = temporary
		parent = smaller
	}
	return minimum
}

write_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8(bits >> (8 * byte))
	}
}

@(export)
priority_queue_sort :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	raw_count := input[0]
	if raw_count < 0 || raw_count > MAX_COUNT || int(length) != 1 + int(raw_count) do return -1
	count := int(raw_count)
	for index := 0; index < count; index += 1 {
		if input[index + 1] < -2147483648 || input[index + 1] > 2147483647 do return -1
	}
	byte_count := 4 * count
	if output == nil || int(output_capacity) < byte_count do return -2

	heap: [MAX_COUNT]i32 = {}
	heap_size := 0
	for index := 0; index < count; index += 1 {
		heap_push(&heap[0], &heap_size, i32(input[index + 1]))
	}
	for index := 0; index < count; index += 1 {
		write_i32_le(output, 4 * index, heap_pop(&heap[0], &heap_size))
	}
	return i64(byte_count)
}
