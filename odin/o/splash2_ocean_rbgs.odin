package splash2_ocean_rbgs

import "core:c"
import "core:math"

MAX_CELLS :: 64
MAX_INPUT :: 132

@(export)
splash2_ocean_rbgs :: proc "c" (input: [^]f64, input_length: c.size_t,
    output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > MAX_INPUT do return -1
	for i in 0..<int(input_length) { if !math.is_finite(input[i]) do return -1 }
	side_value := input[0]
	if side_value != 4 && side_value != 6 && side_value != 8 do return -1
	side := int(side_value)
	cells := side * side
	if input_length != c.size_t(3+2*cells) do return -1
	eigenvalue_squared, spacing := input[1], input[2]
	if eigenvalue_squared < 0 || eigenvalue_squared > 2 || spacing < 0.125 || spacing > 1 do return -1
	factor := 4.0 - eigenvalue_squared*spacing*spacing
	if factor <= 0 do return -1

	grid: [MAX_CELLS]f64
	rhs: [MAX_CELLS]f64
	for i in 0..<cells {
		grid[i] = input[3+i]
		rhs[i] = input[3+cells+i]
		if grid[i] < -8 || grid[i] > 8 || rhs[i] < -8 || rhs[i] > 8 do return -1
	}
	needed := 1+cells
	if output == nil || output_capacity < c.size_t(needed) do return -2

	max_change := 0.0
	for color in 0..<2 {
		for row in 1..<side-1 {
			for column in 1..<side-1 {
				if (row+column)%2 != color do continue
				index := row*side+column
				neighbors := grid[index+1]+grid[index-1]+grid[index-side]+grid[index+side]
				old_value := grid[index]
				updated := (neighbors-rhs[index])/factor
				change := math.abs_f64(old_value-updated)
				if change > max_change do max_change = change
				grid[index] = updated
			}
		}
	}
	output[0] = max_change
	for i in 0..<cells { output[i+1] = grid[i] }
	return i64(needed)
}
