module priority_queue_sort

const max_count = 128
const max_input_length = 130

fn heap_push(mut heap []i32, mut size int, value i32) {
	mut child := size
	size++
	heap[child] = value
	for child > 0 {
		parent := (child - 1) / 2
		if heap[parent] <= heap[child] { break }
		heap[parent], heap[child] = heap[child], heap[parent]
		child = parent
	}
}

fn heap_pop(mut heap []i32, mut size int) i32 {
	minimum := heap[0]
	size--
	if size == 0 { return minimum }
	heap[0] = heap[size]
	mut parent := 0
	for {
		left := 2 * parent + 1
		if left >= size { break }
		right := left + 1
		smaller := left
		if right < size && heap[right] < heap[left] { smaller = right }
		if heap[parent] <= heap[smaller] { break }
		heap[parent], heap[smaller] = heap[smaller], heap[parent]
		parent = smaller
	}
	return minimum
}

fn write_i32_le(mut output &u8, offset int, value i32) {
	bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits >> (8 * byte)) }
	}
}

@[export: 'priority_queue_sort']
pub fn priority_queue_sort(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > usize(max_input_length) { return -1 }
		raw_count := input[0]
		if raw_count < 0 || raw_count > i64(max_count) || int(length) != 1 + int(raw_count) { return -1 }
		count := int(raw_count)
		for index in 0 .. count {
			if input[index + 1] < -2147483648 || input[index + 1] > 2147483647 { return -1 }
		}
		byte_count := 4 * count
		if output == nil || int(output_capacity) < byte_count { return -2 }

		mut heap := []i32{len: max_count, init: 0}
		mut heap_size := 0
		for index in 0 .. count {
			heap_push(mut heap, mut heap_size, i32(input[index + 1]))
		}
		for index in 0 .. count {
			write_i32_le(mut output, 4 * index, heap_pop(mut heap, mut heap_size))
		}
		return i64(byte_count)
	}
}
