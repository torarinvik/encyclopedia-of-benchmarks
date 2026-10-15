package area_of_island

import "core:c"

MAX_ROWS :: 64
MAX_COLUMNS :: 64
MAX_CELLS :: MAX_ROWS * MAX_COLUMNS

// Return the size of the largest four-connected nonzero region.
@(export)
area_of_island :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || input[0] < 1 || input[0] > MAX_ROWS || input[1] < 0 || input[1] > MAX_COLUMNS do return -1
	rows := int(input[0])
	columns := int(input[1])
	cells := rows * columns
	if length != c.size_t(cells + 2) do return -1

	visited: [MAX_CELLS]bool
	stack: [MAX_CELLS]int
	maximum_area := 0
	for start := 0; start < cells; start += 1 {
		if input[2 + start] == 0 || visited[start] do continue
		top := 0
		area := 0
		visited[start] = true
		stack[top] = start
		top += 1
		for top > 0 {
			top -= 1
			current := stack[top]
			area += 1
			row := current / columns
			column := current % columns
			if row > 0 {
				neighbor := current - columns
				if !visited[neighbor] && input[2 + neighbor] != 0 { visited[neighbor] = true; stack[top] = neighbor; top += 1 }
			}
			if column + 1 < columns {
				neighbor := current + 1
				if !visited[neighbor] && input[2 + neighbor] != 0 { visited[neighbor] = true; stack[top] = neighbor; top += 1 }
			}
			if row + 1 < rows {
				neighbor := current + columns
				if !visited[neighbor] && input[2 + neighbor] != 0 { visited[neighbor] = true; stack[top] = neighbor; top += 1 }
			}
			if column > 0 {
				neighbor := current - 1
				if !visited[neighbor] && input[2 + neighbor] != 0 { visited[neighbor] = true; stack[top] = neighbor; top += 1 }
			}
		}
		maximum_area = max(maximum_area, area)
	}
	return i64(maximum_area)
}
