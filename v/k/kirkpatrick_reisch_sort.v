struct HeapNode {
	value i64
	block int
	offset int
}

fn heap_less(left HeapNode, right HeapNode) bool {
	if left.value != right.value { return left.value < right.value }
	if left.block != right.block { return left.block < right.block }
	return left.offset < right.offset
}

fn heap_push(mut heap [17]HeapNode, mut length int, value HeapNode) {
	mut position := length
	length++
	for position > 0 {
		parent := (position - 1) / 2
		if !heap_less(value, heap[parent]) { break }
		heap[position] = heap[parent]
		position = parent
	}
	heap[position] = value
}

fn heap_pop(mut heap [17]HeapNode, mut length int) HeapNode {
	minimum := heap[0]
	length--
	last := heap[length]
	if length == 0 { return minimum }
	mut position := 0
	for position * 2 + 1 < length {
		mut child := position * 2 + 1
		if child + 1 < length && heap_less(heap[child + 1], heap[child]) { child++ }
		if !heap_less(heap[child], last) { break }
		heap[position] = heap[child]
		position = child
	}
	heap[position] = last
	return minimum
}

fn write_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		output[offset + byte] = u8((bits >> (byte * 8)) & 0xff)
	}
}

@[export: 'kirkpatrick_reisch_sort']
pub fn kirkpatrick_reisch_sort(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > 258 { return -1 }
		if input[0] < 0 || input[0] > 256 { return -1 }
		count := int(input[0])
		if input_length != usize(count + 1) { return -1 }

		mut blocks := [256]i64{}
		for index in 0 .. count { blocks[index] = input[index + 1] }
		mut starts := [17]int{}
		mut lengths := [17]int{}
		mut block_count := 0
		mut block_size := 1
		if count > 1 {
			for (block_size + 1) * (block_size + 1) <= count { block_size++ }
			mut start := 0
			for start < count {
				length := if count - start < block_size { count - start } else { block_size }
				starts[block_count] = start
				lengths[block_count] = length
				block_count++
				for index in 1 .. length {
					value := blocks[start + index]
					mut position := index
					for position > 0 && blocks[start + position - 1] > value {
						blocks[start + position] = blocks[start + position - 1]
						position--
					}
					blocks[start + position] = value
				}
				start += block_size
			}
		} else if count == 1 {
			starts[0] = 0
			lengths[0] = 1
			block_count = 1
		}

		mut sorted := [256]i64{}
		mut sorted_count := 0
		mut heap := [17]HeapNode{}
		mut heap_length := 0
		for block in 0 .. block_count {
			heap_push(mut heap, mut heap_length, HeapNode{blocks[starts[block]], block, 0})
		}
		for heap_length > 0 {
			current := heap_pop(mut heap, mut heap_length)
			sorted[sorted_count] = current.value
			sorted_count++
			next := current.offset + 1
			if next < lengths[current.block] {
				heap_push(mut heap, mut heap_length, HeapNode{blocks[starts[current.block] + next], current.block, next})
			}
		}

		output_bytes := sorted_count * 8
		if output_bytes > 2048 { return -1 }
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. sorted_count { write_i64_le(mut output, index * 8, sorted[index]) }
		return i64(output_bytes)
	}
}
