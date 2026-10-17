module randomized_heap

const max_ops = 64
const max_input_length = 129
const max_output_words = 1 + 2 * max_ops
const max_output_bytes = 4 * max_output_words

fn put_i32_le(mut output &u8, offset int, value i32) {
	mut bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'randomized_heap']
pub fn randomized_heap(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > usize(max_input_length) { return -1 }
		if input[0] < 0 || input[0] > max_ops { return -1 }
		operation_count := int(input[0])
		mut heap := [max_ops]i32{}
		mut words := [max_output_words]i32{}
		mut heap_size := 0
		mut word_count := 1
		mut query_count := 0
		mut pos := 1
		for _ in 0 .. operation_count {
			if pos >= int(length) { return -1 }
			opcode := input[pos]
			pos++
			if opcode == 0 {
				if pos >= int(length) { return -1 }
				raw := input[pos]
				pos++
				if raw < -2147483648 || raw > 2147483647 { return -1 }
				mut index := heap_size
				heap[index] = i32(raw)
				for index > 0 {
					parent := (index - 1) / 2
					if heap[parent] <= heap[index] { break }
					tmp := heap[parent]
					heap[parent] = heap[index]
					heap[index] = tmp
					index = parent
				}
				heap_size++
			} else if opcode == 1 || opcode == 2 {
				if heap_size == 0 { return -1 }
				value := heap[0]
				if opcode == 2 {
					heap_size--
					if heap_size > 0 {
						heap[0] = heap[heap_size]
						mut index := 0
						for {
							left := 2 * index + 1
							if left >= heap_size { break }
							right := left + 1
							mut child := left
							if right < heap_size && heap[right] < heap[left] { child = right }
							if heap[index] <= heap[child] { break }
							tmp := heap[index]
							heap[index] = heap[child]
							heap[child] = tmp
							index = child
						}
					}
				}
				words[word_count] = if opcode == 1 { 1 } else { 2 }
				words[word_count + 1] = value
				word_count += 2
				query_count++
			} else if opcode == 3 {
				words[word_count] = 3
				words[word_count + 1] = if heap_size == 0 { 1 } else { 0 }
				word_count += 2
				query_count++
			} else { return -1 }
		}
		if pos != int(length) || word_count > max_output_words { return -1 }
		words[0] = i32(query_count)
		bytes := word_count * 4
		if output == nil || capacity < usize(bytes) { return -2 }
		mut buffer := [max_output_bytes]u8{}
		for i in 0 .. word_count { put_i32_le(mut buffer[0], i * 4, words[i]) }
		for i in 0 .. bytes { output[i] = buffer[i] }
		return i64(bytes)
	}
}
