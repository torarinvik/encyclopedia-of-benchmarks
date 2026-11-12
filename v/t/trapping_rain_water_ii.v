module trapping_rain_water_ii

// Min-heap boundary flood for a bounded row-major terrain.
@[export: 'trapping_rain_water_ii']
pub fn trapping_rain_water_ii(input &i64, length usize) i64 {
	if length < 2 || length > 66 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 8 || input[1] < 1 || input[1] > 8 { return -1 }
		rows := int(input[0])
		cols := int(input[1])
		if length != usize(2 + rows * cols) { return -1 }
		mut heights := [64]i64{}
		for cell in 0 .. rows * cols {
			height := input[2 + cell]
			if height < 0 || height > 1000 { return -1 }
			heights[cell] = height
		}
		mut visited := [64]bool{}
		mut heap := [64]i64{}
		mut heap_size := 0
		for row in 0 .. rows {
			for col in 0 .. cols {
				if row == 0 || row + 1 == rows || col == 0 || col + 1 == cols {
					cell := row * cols + col
					if !visited[cell] {
						visited[cell] = true
						key := heights[cell] * 64 + i64(cell)
						mut position := heap_size
						heap_size++
						for position > 0 {
							parent := (position - 1) / 2
							if heap[parent] <= key { break }
							heap[position] = heap[parent]
							position = parent
						}
						heap[position] = key
					}
				}
			}
		}
		dr := [-1, 1, 0, 0]
		dc := [0, 0, -1, 1]
		mut retained := i64(0)
		for heap_size > 0 {
			key := heap[0]
			heap_size--
			if heap_size > 0 {
				last := heap[heap_size]
				mut position := 0
				for 2 * position + 1 < heap_size {
					mut child := 2 * position + 1
					if child + 1 < heap_size && heap[child + 1] < heap[child] { child++ }
					if heap[child] >= last { break }
					heap[position] = heap[child]
					position = child
				}
				heap[position] = last
			}
			level := key / 64
			cell := int(key % 64)
			row := cell / cols
			col := cell % cols
			for direction in 0 .. 4 {
				nr := row + dr[direction]
				nc := col + dc[direction]
				if nr < 0 || nr >= rows || nc < 0 || nc >= cols { continue }
				neighbor := nr * cols + nc
				if visited[neighbor] { continue }
				visited[neighbor] = true
				height := heights[neighbor]
				if height < level { retained += level - height }
				next_level := if height > level { height } else { level }
				next_key := next_level * 64 + i64(neighbor)
				mut position := heap_size
				heap_size++
				for position > 0 {
					parent := (position - 1) / 2
					if heap[parent] <= next_key { break }
					heap[position] = heap[parent]
					position = parent
				}
				heap[position] = next_key
			}
		}
		return retained
	}
}
