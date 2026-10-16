module smallest_range

@[export: 'smallest_range']
pub fn smallest_range(packed &i64, length usize) i64 {
	if unsafe { packed == nil } || length < 2 || length > 273 { return -1 }
	count_value := unsafe { packed[0] }
	if count_value < 1 || count_value > 16 { return -1 }
	count := int(count_value)
	mut values := [16][16]i64{init: 0}
	mut lengths := [16]int{init: 0}
	mut positions := [16]int{init: 0}
	mut heap := [16]int{init: 0}
	mut offset := 1
	mut total := 0
	mut current_max := i64(-1000000001)
	for i in 0 .. count {
		if offset >= int(length) { return -1 }
		list_len := unsafe { packed[offset] }
		if list_len < 1 || list_len > 16 { return -1 }
		lengths[i] = int(list_len)
		offset++
		if lengths[i] > 256 - total || offset + lengths[i] > int(length) { return -1 }
		total += lengths[i]
		for j in 0 .. lengths[i] {
			value := unsafe { packed[offset] }
			if value < -1000000000 || value > 1000000000 || (j > 0 && value < values[i][j - 1]) { return -1 }
			values[i][j] = value
			offset++
		}
		heap[i] = i
		if values[i][0] > current_max { current_max = values[i][0] }
	}
	if offset != int(length) { return -1 }
	heap_size := count
	for start := heap_size / 2 - 1; start >= 0; start-- {
		mut root := start
		for {
			mut child := root * 2 + 1
			if child >= heap_size { break }
			if child + 1 < heap_size && less_head(values, positions, heap[child + 1], heap[child]) { child++ }
			if !less_head(values, positions, heap[child], heap[root]) { break }
			heap[root], heap[child] = heap[child], heap[root]
			root = child
		}
	}
	mut best_lo := i64(0)
	mut best_hi := i64(0)
	mut best_width := i64(9223372036854775807)
	for {
		list := heap[0]
		lo := values[list][positions[list]]
		width := current_max - lo
		if width < best_width { best_width = width; best_lo = lo; best_hi = current_max }
		positions[list]++
		if positions[list] == lengths[list] { break }
		if values[list][positions[list]] > current_max { current_max = values[list][positions[list]] }
		mut root := 0
		for {
			mut child := root * 2 + 1
			if child >= heap_size { break }
			if child + 1 < heap_size && less_head(values, positions, heap[child + 1], heap[child]) { child++ }
			if !less_head(values, positions, heap[child], heap[root]) { break }
			heap[root], heap[child] = heap[child], heap[root]
			root = child
		}
	}
	return (best_lo + 1000000000) * 2000000001 + best_hi + 1000000000
}

fn less_head(values [16][16]i64, positions [16]int, a int, b int) bool {
	left := values[a][positions[a]]
	right := values[b][positions[b]]
	return left < right || (left == right && a < b)
}
