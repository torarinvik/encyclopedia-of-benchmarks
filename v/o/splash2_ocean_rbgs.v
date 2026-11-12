import math

const max_cells = 64
const max_input usize = 132

@[export: 'splash2_ocean_rbgs']
pub fn splash2_ocean_rbgs(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > max_input { return -1 }
		for i in 0 .. input_length { if !input[i].is_finite() { return -1 } }
		side_value := input[0]
		if side_value != 4.0 && side_value != 6.0 && side_value != 8.0 { return -1 }
		side := int(side_value)
		cells := side * side
		if input_length != usize(3 + 2 * cells) { return -1 }
		eigenvalue_squared := input[1]
		spacing := input[2]
		if eigenvalue_squared < 0.0 || eigenvalue_squared > 2.0 || spacing < 0.125 || spacing > 1.0 { return -1 }
		factor := 4.0 - eigenvalue_squared * spacing * spacing
		if factor <= 0.0 { return -1 }

		mut grid := [max_cells]f64{}
		mut rhs := [max_cells]f64{}
		for i in 0 .. cells {
			grid[i] = input[3 + i]
			rhs[i] = input[3 + cells + i]
			if grid[i] < -8.0 || grid[i] > 8.0 || rhs[i] < -8.0 || rhs[i] > 8.0 { return -1 }
		}
		needed := 1 + cells
		if output == nil || output_capacity < usize(needed) { return -2 }

		mut max_change := 0.0
		for color in 0 .. 2 {
			for row in 1 .. side - 1 {
				for column in 1 .. side - 1 {
					if (row + column) % 2 != color { continue }
					index := row * side + column
					neighbors := grid[index + 1] + grid[index - 1] + grid[index - side] + grid[index + side]
					old_value := grid[index]
					updated := (neighbors - rhs[index]) / factor
					change := math.abs(old_value - updated)
					if change > max_change { max_change = change }
					grid[index] = updated
				}
			}
		}
		output[0] = max_change
		for i in 0 .. cells { output[i + 1] = grid[i] }
		return i64(needed)
	}
}
