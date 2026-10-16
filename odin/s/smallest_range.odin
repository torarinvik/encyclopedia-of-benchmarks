package smallest_range

import "core:c"

less_head :: proc(values: [16][16]i64, positions: [16]int, a, b: int) -> bool {
	left := values[a][positions[a]]
	right := values[b][positions[b]]
	return left < right || (left == right && a < b)
}

sift_down :: proc(heap: ^[16]int, size, initial_root: int, values: [16][16]i64, positions: [16]int) {
	root := initial_root
	for {
		child := root * 2 + 1
		if child >= size do return
		if child + 1 < size && less_head(values, positions, heap[child + 1], heap[child]) do child += 1
		if !less_head(values, positions, heap[child], heap[root]) do return
		swap := heap[root]
		heap[root] = heap[child]
		heap[child] = swap
		root = child
	}
}

@(export)
smallest_range :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 2 || length > 273 do return -1
	if packed[0] < 1 || packed[0] > 16 do return -1
	count := int(packed[0])
	values: [16][16]i64
	lengths: [16]int
	positions: [16]int
	heap: [16]int
	offset := 1
	total := 0
	current_max := i64(-1000000001)
	for i in 0..<count {
		if offset >= int(length) do return -1
		list_len := packed[offset]
		if list_len < 1 || list_len > 16 do return -1
		lengths[i] = int(list_len)
		offset += 1
		if lengths[i] > 256 - total || offset + lengths[i] > int(length) do return -1
		total += lengths[i]
		for j in 0..<lengths[i] {
			value := packed[offset]
			if value < -1000000000 || value > 1000000000 || (j > 0 && value < values[i][j - 1]) do return -1
			values[i][j] = value
			offset += 1
		}
		heap[i] = i
		if values[i][0] > current_max do current_max = values[i][0]
	}
	if offset != int(length) do return -1
	heap_size := count
	for start := heap_size / 2 - 1; start >= 0; start -= 1 {
		sift_down(&heap, heap_size, start, values, positions)
	}
	best_lo, best_hi, best_width := i64(0), i64(0), i64(9223372036854775807)
	for {
		list := heap[0]
		lo := values[list][positions[list]]
		width := current_max - lo
		if width < best_width { best_width, best_lo, best_hi = width, lo, current_max }
		positions[list] += 1
		if positions[list] == lengths[list] do break
		if values[list][positions[list]] > current_max do current_max = values[list][positions[list]]
		sift_down(&heap, heap_size, 0, values, positions)
	}
	return (best_lo + 1000000000) * 2000000001 + best_hi + 1000000000
}
