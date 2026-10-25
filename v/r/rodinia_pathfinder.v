module rodinia_pathfinder

// Bounded row-wise minimum-cost path through a grid.
@[export: 'rodinia_pathfinder']
pub fn rodinia_pathfinder(input &i64, length usize) i64 {
	if length < 4 || length > 1027 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 32 || input[1] < 1 || input[1] > 32 ||
			input[2] < 1 || input[2] > 4 { return -1 }
		cols := int(input[0]); rows := int(input[1]); height := int(input[2])
		cells := cols * rows
		if length != usize(3 + cells) { return -1 }
		for i := 0; i < cells; i++ {
			if input[3 + i] < 0 || input[3 + i] > 9 { return -1 }
		}
		mut previous := [32]i64{}
		mut current := [32]i64{}
		for col := 0; col < cols; col++ { previous[col] = input[3 + col] }
		mut first := 1
		for first < rows {
			steps := if rows - first < height { rows - first } else { height }
			for step := 0; step < steps; step++ {
				row := first + step
				for col := 0; col < cols; col++ {
					mut best := previous[col]
					if col > 0 && previous[col - 1] < best { best = previous[col - 1] }
					if col + 1 < cols && previous[col + 1] < best { best = previous[col + 1] }
					current[col] = best + input[3 + row * cols + col]
				}
				for col := 0; col < cols; col++ { previous[col] = current[col] }
			}
			first += height
		}
		mut answer := previous[0]
		for col := 1; col < cols; col++ { if previous[col] < answer { answer = previous[col] } }
		return answer
	}
}
