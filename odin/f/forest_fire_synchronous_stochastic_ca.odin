package forest_fire_synchronous_stochastic_ca

import "core:c"

MAX_CELLS :: 64
MAX_INPUT :: 1095

put_word :: proc(output: [^]u8, word: int, value: i64) {
	bits := u64(value)
	for byte in 0..<8 {
		output[word*8+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
forest_fire_synchronous_stochastic_ca :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > c.size_t(MAX_INPUT) do return -1
	if input[0] < 1 || input[0] > 8 || input[1] < 1 || input[1] > 8 ||
		input[2] < 0 || input[2] > 8 || input[3] != 10000 ||
		input[4] < 0 || input[4] > 10000 || input[5] < 0 || input[5] > 10000 do return -1
	rows, cols, steps := int(input[0]), int(input[1]), int(input[2])
	cells := rows * cols
	if length != c.size_t(6 + cells + 2*steps*cells) do return -1
	for i in 0..<cells { if input[6+i] < 0 || input[6+i] > 2 do return -1 }
	for row in 0..<rows { for col in 0..<cols {
		if (row == 0 || row == rows-1 || col == 0 || col == cols-1) && input[6+row*cols+col] != 0 do return -1
	} }
	tape := 6 + cells
	for i in 0..<(2*steps*cells) { if input[tape+i] < 0 || input[tape+i] >= 10000 do return -1 }
	bytes := (1 + 3*steps + cells) * 8
	if output == nil || capacity < c.size_t(bytes) do return -2

	current: [MAX_CELLS]u8 = {}
	next: [MAX_CELLS]u8 = {}
	for i in 0..<cells { current[i] = u8(input[6+i]) }
	put_word(output, 0, i64(steps))
	for tick in 0..<steps {
		for row in 0..<rows {
			for col in 0..<cols {
				site := row*cols+col
				if row == 0 || row == rows-1 || col == 0 || col == cols-1 { next[site] = 0; continue }
				if current[site] == 2 { next[site] = 0; continue }
				if current[site] == 0 {
					next[site] = 0
					if input[tape+tick*cells+site] < input[4] do next[site] = 1
					continue
				}
				near_fire := false
				for r in max(0,row-1)..=min(rows-1,row+1) {
					for cidx in max(0,col-1)..=min(cols-1,col+1) {
						if (r != row || cidx != col) && current[r*cols+cidx] == 2 { near_fire = true }
					}
				}
				strike := input[tape+steps*cells+tick*cells+site]
				next[site] = 1
				if near_fire || strike < input[5] do next[site] = 2
			}
		}
		totals: [3]i64 = {}
		for i in 0..<cells { totals[int(next[i])] += 1 }
		base := 1 + 3*tick
		for state in 0..<3 { put_word(output, base+state, totals[state]) }
		for i in 0..<cells { current[i] = next[i] }
	}
	final_base := 1 + 3*steps
	for i in 0..<cells { put_word(output, final_base+i, i64(current[i])) }
	return i64(bytes)
}
