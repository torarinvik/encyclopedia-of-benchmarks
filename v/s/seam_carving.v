// Adapted from Trekhleb's seam-carving explanation. Copyright (c) 2018
// Oleksii Trekhleb; MIT License, see benchmarks/s/seam_carving/LICENSE.txt.
module seam_carving

import math

@[export: 'seam_carving']
pub fn seam_carving(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 39 { return -1 }
	width_value := unsafe { input[0] }
	height_value := unsafe { input[1] }
	if width_value < 2 || width_value > 6 || height_value < 1 || height_value > 6 { return -1 }
	width := int(width_value)
	height := int(height_value)
	if int(length) != 2 + width * height { return -1 }
	for index in 0 .. width * height {
		pixel := unsafe { input[2 + index] }
		if pixel < 0 || pixel > 255 { return -1 }
	}

	mut energy := [6][6]f64{}
	mut cumulative := [6][6]f64{}
	mut previous_x := [6][6]int{}
	mut seam_x := [6]int{}
	for y in 0 .. height {
		row := y * width
		for x in 0 .. width {
			middle := f64(unsafe { input[2 + row + x] })
			mut left_energy := f64(0)
			mut right_energy := f64(0)
			if x > 0 {
				difference := f64(unsafe { input[2 + row + x - 1] }) - middle
				left_energy = difference * difference + difference * difference + difference * difference
			}
			if x + 1 < width {
				difference := f64(unsafe { input[2 + row + x + 1] }) - middle
				right_energy = difference * difference + difference * difference + difference * difference
			}
			energy[y][x] = math.sqrt(left_energy + right_energy)
		}
	}
	for x in 0 .. width { cumulative[0][x] = energy[0][x] }
	for y in 1 .. height {
		for x in 0 .. width {
			mut minimum := f64(1.0e300)
			mut best_x := x
			start := if x == 0 { 0 } else { x - 1 }
			last := if x + 1 < width { x + 1 } else { width - 1 }
			for candidate in start .. last + 1 {
				if cumulative[y - 1][candidate] < minimum {
					minimum = cumulative[y - 1][candidate]
					best_x = candidate
				}
			}
			cumulative[y][x] = minimum + energy[y][x]
			previous_x[y][x] = best_x
		}
	}
	mut last_x := 0
	mut minimum := cumulative[height - 1][0]
	for x in 1 .. width {
		if cumulative[height - 1][x] < minimum {
			minimum = cumulative[height - 1][x]
			last_x = x
		}
	}
	seam_x[height - 1] = last_x
	mut y := height - 1
	for y > 0 {
		seam_x[y - 1] = previous_x[y][seam_x[y]]
		y--
	}

	needed := height * (width - 1)
	if unsafe { output == nil } || output_capacity < usize(needed) { return -2 }
	mut staged := [30]u8{}
	mut position := 0
	for row_index in 0 .. height {
		for x in 0 .. width {
			if x != seam_x[row_index] {
				staged[position] = u8(unsafe { input[2 + row_index * width + x] })
				position++
			}
		}
	}
	for index in 0 .. needed { unsafe { output[index] = staged[index] } }
	return i64(needed)
}
