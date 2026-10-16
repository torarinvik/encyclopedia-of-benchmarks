module min_heap_bulk_extract_sorted

fn store_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'min_heap_bulk_extract_sorted']
pub fn min_heap_bulk_extract_sorted(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 2 || length > 4096 || unsafe { values == nil } { return -1 }
	unsafe {
		raw_count := values[0]
		if raw_count < 1 || raw_count > 4095 || length != usize(raw_count + 1) { return -1 }
		count := int(raw_count)
		mut heap := [4095]i64{}
		for index in 0 .. count {
			value := values[index + 1]
			if value < -2_147_483_648 || value > 2_147_483_647 { return -1 }
			mut position := index
			heap[position] = value
			for position > 0 {
				parent := (position - 1) / 2
				if heap[parent] <= heap[position] { break }
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
					mut smallest := index_down
					left := index_down * 2 + 1
					right := left + 1
					if left < remaining && heap[left] < heap[smallest] { smallest = left }
					if right < remaining && heap[right] < heap[smallest] { smallest = right }
					if smallest == index_down { break }
					heap[index_down], heap[smallest] = heap[smallest], heap[index_down]
					index_down = smallest
				}
			}
		}
		return i64(output_bytes)
	}
}
