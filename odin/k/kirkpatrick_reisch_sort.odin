package kirkpatrick_reisch_sort

import "core:c"

MAX_ELEMENTS :: 256
MAX_BLOCKS :: 17
MAX_PARSEABLE_INPUT_LENGTH :: 258
MAX_OUTPUT_BYTES :: 2048

Heap_Node :: struct {
	value: i64,
	block: int,
	offset: int,
}

heap_less :: proc(left, right: Heap_Node) -> bool {
	if left.value != right.value do return left.value < right.value
	if left.block != right.block do return left.block < right.block
	return left.offset < right.offset
}

heap_push :: proc(heap: ^[MAX_BLOCKS]Heap_Node, length: ^int, value: Heap_Node) {
	position := length^
	length^ += 1
	for position > 0 {
		parent := (position - 1) / 2
		if !heap_less(value, heap[parent]) do break
		heap[position] = heap[parent]
		position = parent
	}
	heap[position] = value
}

heap_pop :: proc(heap: ^[MAX_BLOCKS]Heap_Node, length: ^int) -> Heap_Node {
	minimum := heap[0]
	length^ -= 1
	last := heap[length^]
	if length^ == 0 do return minimum
	position := 0
	for position * 2 + 1 < length^ {
		child := position * 2 + 1
		if child + 1 < length^ && heap_less(heap[child + 1], heap[child]) do child += 1
		if !heap_less(heap[child], last) do break
		heap[position] = heap[child]
		position = child
	}
	heap[position] = last
	return minimum
}

write_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8((bits >> (byte*8)) & 0xff)
	}
}

@(export)
kirkpatrick_reisch_sort :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_ELEMENTS do return -1
	count := int(input[0])
	if int(input_length) != count + 1 do return -1

	blocks: [MAX_ELEMENTS]i64
	for index := 0; index < count; index += 1 { blocks[index] = input[index+1] }
	starts: [MAX_BLOCKS]int
	lengths: [MAX_BLOCKS]int
	block_count := 0
	block_size := 1
	if count > 1 {
		for (block_size+1)*(block_size+1) <= count { block_size += 1 }
		for start := 0; start < count; start += block_size {
			length := count - start
			if length > block_size { length = block_size }
			starts[block_count] = start
			lengths[block_count] = length
			block_count += 1
			for index := 1; index < length; index += 1 {
				value := blocks[start+index]
				position := index
				for position > 0 && blocks[start+position-1] > value {
					blocks[start+position] = blocks[start+position-1]
					position -= 1
				}
				blocks[start+position] = value
			}
		}
	} else if count == 1 {
		starts[0] = 0
		lengths[0] = 1
		block_count = 1
	}

	sorted: [MAX_ELEMENTS]i64
	sorted_count := 0
	heap: [MAX_BLOCKS]Heap_Node
	heap_length := 0
	for block := 0; block < block_count; block += 1 {
		heap_push(&heap, &heap_length, Heap_Node{blocks[starts[block]], block, 0})
	}
	for heap_length > 0 {
		current := heap_pop(&heap, &heap_length)
		sorted[sorted_count] = current.value
		sorted_count += 1
		next := current.offset + 1
		if next < lengths[current.block] {
			heap_push(&heap, &heap_length, Heap_Node{blocks[starts[current.block]+next], current.block, next})
		}
	}

	output_bytes := sorted_count * 8
	if output_bytes > MAX_OUTPUT_BYTES do return -1
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < sorted_count; index += 1 { write_i64_le(output, index*8, sorted[index]) }
	return i64(output_bytes)
}
