package trapping_rain_water_ii

import "core:c"

MAX_CELLS :: 64

heap_push :: proc(heap: ^[MAX_CELLS]i64, size: ^int, key: i64) {
	position := size^
	size^ += 1
	for position > 0 {
		parent := (position - 1) / 2
		if heap[parent] <= key do break
		heap[position] = heap[parent]
		position = parent
	}
	heap[position] = key
}

heap_pop :: proc(heap: ^[MAX_CELLS]i64, size: ^int) -> i64 {
	minimum := heap[0]
	size^ -= 1
	if size^ > 0 {
		last := heap[size^]
		position := 0
		for 2 * position + 1 < size^ {
			child := 2 * position + 1
			if child + 1 < size^ && heap[child + 1] < heap[child] do child += 1
			if heap[child] >= last do break
			heap[position] = heap[child]
			position = child
		}
		heap[position] = last
	}
	return minimum
}

@(export)
trapping_rain_water_ii :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 66 do return -1
	if input[0] < 1 || input[0] > 8 || input[1] < 1 || input[1] > 8 do return -1
	rows, cols := int(input[0]), int(input[1])
	if int(length) != 2 + rows * cols do return -1
	_heights: [MAX_CELLS]i64
	for cell := 0; cell < rows * cols; cell += 1 {
		height := input[2 + cell]
		if height < 0 || height > 1000 do return -1
		_heights[cell] = height
	}
	visited: [MAX_CELLS]bool
	heap: [MAX_CELLS]i64
	heap_size := 0
	for row := 0; row < rows; row += 1 {
		for col := 0; col < cols; col += 1 {
			if row == 0 || row + 1 == rows || col == 0 || col + 1 == cols {
				cell := row * cols + col
				if !visited[cell] {
					visited[cell] = true
					heap_push(&heap, &heap_size, _heights[cell] * 64 + i64(cell))
				}
			}
		}
	}
	dr := [4]int{-1, 1, 0, 0}
	dc := [4]int{0, 0, -1, 1}
	retained := i64(0)
	for heap_size > 0 {
		key := heap_pop(&heap, &heap_size)
		level := key / 64
		cell := int(key % 64)
		row, col := cell / cols, cell % cols
		for direction := 0; direction < 4; direction += 1 {
			nr, nc := row + dr[direction], col + dc[direction]
			if nr < 0 || nr >= rows || nc < 0 || nc >= cols do continue
			neighbor := nr * cols + nc
			if visited[neighbor] do continue
			visited[neighbor] = true
			height := _heights[neighbor]
			if height < level do retained += level - height
			heap_push(&heap, &heap_size, max(level, height) * 64 + i64(neighbor))
		}
	}
	return retained
}
