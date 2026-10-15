module heap_max_push_peek_pop

fn store_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'heap_max_push_peek_pop']
pub fn heap_max_push_peek_pop(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 2 || length > 257 || unsafe { values == nil } { return -1 }
	unsafe {
		raw_count := values[0]
		if raw_count < 1 || raw_count > 256 || length != usize(raw_count + 1) { return -1 }
		count := int(raw_count)
		mut heap := [256]i64{}
		for index in 0 .. count {
			value := values[index + 1]
			if value < 1 || value > 1_000_000_000 { return -1 }
			mut position := index
			heap[position] = value
			for position > 0 {
				parent := (position - 1) / 2
				if heap[parent] >= heap[position] { break }
				heap[parent], heap[position] = heap[position], heap[parent]
				position = parent
			}
		}
		output_bytes := 8 * count
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		mut remaining := count
		for index in 0 .. count {
			store_i64_le(mut output, 8 * index, heap[0])
			remaining--
			if remaining > 0 {
				heap[0] = heap[remaining]
				mut index_down := 0
				for {
					mut largest := index_down
					left := index_down * 2 + 1
					right := left + 1
					if left < remaining && heap[left] > heap[largest] { largest = left }
					if right < remaining && heap[right] > heap[largest] { largest = right }
					if largest == index_down { break }
					heap[index_down], heap[largest] = heap[largest], heap[index_down]
					index_down = largest
				}
			}
		}
		return i64(output_bytes)
	}
}
