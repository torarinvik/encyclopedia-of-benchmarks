module binary_heap_indexed_operations

@[export: 'binary_heap_indexed_operations']
pub fn binary_heap_indexed_operations(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 { return -1 }
	unsafe {
		if values[0] < 1 || values[0] > 256 || values[1] < 0 || values[1] > 512 || length != usize(2 + values[1] * 3) { return -1 }
		mut heap := [256]i64{}
		mut size := 0
		mut outputs := 0
		for index in 0 .. int(values[1]) {
			op := values[2 + 3 * index]
			a := values[3 + 3 * index]
			b := values[4 + 3 * index]
			if op == 0 {
				if a < -2147483648 || a > 2147483647 || b != 0 { return -1 }
				if size < int(values[0]) {
					heap[size] = a
					mut i := size
					for i > 0 { parent := (i - 1) / 2; if heap[parent] <= heap[i] { break }; heap[parent], heap[i] = heap[i], heap[parent]; i = parent }
					size++
				}
			} else if op == 1 || op == 2 {
				if a != 0 || b != 0 || (op == 1 && size == 0) { return -1 }
				if unsafe { output == nil } || (outputs + 1) * 8 > output_capacity { return -2 }
				result := i64(2147483647)
				if size > 0 { result = heap[0] }
				if op == 2 && size > 0 { size--; heap[0] = heap[size]; if size > 0 { sift_down(&heap[0], size, 0) } }
				store_i64_le(output, outputs, result)
				outputs++
			} else if op == 3 {
				if a < 0 || a >= i64(size) || b < -2147483648 || b > 2147483647 || b > heap[int(a)] { return -1 }
				heap[int(a)] = b
				mut i := int(a)
				for i > 0 { parent := (i - 1) / 2; if heap[parent] <= heap[i] { break }; heap[parent], heap[i] = heap[i], heap[parent]; i = parent }
			} else if op == 4 {
				if a < 0 || a >= i64(size) || b != 0 { return -1 }
				heap[int(a)] = -2147483648
				mut i := int(a)
				for i > 0 { parent := (i - 1) / 2; if heap[parent] <= heap[i] { break }; heap[parent], heap[i] = heap[i], heap[parent]; i = parent }
				size--; heap[0] = heap[size]; if size > 0 { sift_down(&heap[0], size, 0) }
			} else { return -1 }
		}
		return i64(outputs * 8)
	}
}

fn sift_down(heap &i64, size int, start int) {
	unsafe {
		mut i := start
		for {
			left := 2 * i + 1
			right := left + 1
			mut smallest := i
			if left < size && heap[left] < heap[smallest] { smallest = left }
			if right < size && heap[right] < heap[smallest] { smallest = right }
			if smallest == i { return }
			heap[i], heap[smallest] = heap[smallest], heap[i]
			i = smallest
		}
	}
}

fn store_i64_le(output &u8, slot int, value i64) {
	unsafe {
		mut bits := u64(value)
		for b in 0 .. 8 { output[slot * 8 + b] = u8(bits & 255); bits >>= 8 }
	}
}
