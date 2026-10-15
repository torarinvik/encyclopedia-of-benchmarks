module area_of_island

// Return the size of the largest four-connected nonzero region.
@[export: 'area_of_island']
pub fn area_of_island(input &i64, length usize) i64 {
	if length < 2 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 64 || input[1] < 0 || input[1] > 64 { return -1 }
		rows := int(input[0])
		columns := int(input[1])
		cells := rows * columns
		if int(length) != cells + 2 { return -1 }
		mut visited := [4096]bool{}
		mut stack := [4096]int{}
		mut maximum_area := 0
		for start in 0 .. cells {
			if input[2 + start] == 0 || visited[start] { continue }
			mut top := 0
			mut area := 0
			visited[start] = true
			stack[top] = start
			top++
			for top > 0 {
				top--
				current := stack[top]
				area++
				row := current / columns
				column := current % columns
				if row > 0 {
					neighbor := current - columns
					if !visited[neighbor] && input[2 + neighbor] != 0 { visited[neighbor] = true; stack[top] = neighbor; top++ }
				}
				if column + 1 < columns {
					neighbor := current + 1
					if !visited[neighbor] && input[2 + neighbor] != 0 { visited[neighbor] = true; stack[top] = neighbor; top++ }
				}
				if row + 1 < rows {
					neighbor := current + columns
					if !visited[neighbor] && input[2 + neighbor] != 0 { visited[neighbor] = true; stack[top] = neighbor; top++ }
				}
				if column > 0 {
					neighbor := current - 1
					if !visited[neighbor] && input[2 + neighbor] != 0 { visited[neighbor] = true; stack[top] = neighbor; top++ }
				}
			}
			maximum_area = max(maximum_area, area)
		}
		return i64(maximum_area)
	}
}
