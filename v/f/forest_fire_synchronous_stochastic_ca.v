module forest_fire_synchronous_stochastic_ca

const maxCells = 64
const maxInput = 1095

fn put_word(mut output &u8, word int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		output[word * 8 + byte] = u8(bits & 255)
		bits >>= 8
	}
}

pub fn forest_fire_synchronous_stochastic_ca(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 6 || length > maxInput { return -1 }
	if input[0] < 1 || input[0] > 8 || input[1] < 1 || input[1] > 8 ||
		input[2] < 0 || input[2] > 8 || input[3] != 10000 ||
		input[4] < 0 || input[4] > 10000 || input[5] < 0 || input[5] > 10000 { return -1 }
	rows, cols, steps := int(input[0]), int(input[1]), int(input[2])
	cells := rows * cols
	if length != usize(6 + cells + 2 * steps * cells) { return -1 }
	for i in 0 .. cells { if input[6 + i] < 0 || input[6 + i] > 2 { return -1 } }
	for row in 0 .. rows { for col in 0 .. cols {
		if (row == 0 || row == rows - 1 || col == 0 || col == cols - 1) && input[6 + row * cols + col] != 0 { return -1 }
	} }
	tape := 6 + cells
	for i in 0 .. 2 * steps * cells { if input[tape + i] < 0 || input[tape + i] >= 10000 { return -1 } }
	bytes := (1 + 3 * steps + cells) * 8
	if output == nil || capacity < usize(bytes) { return -2 }

	mut current := [maxCells]u8{}
	mut next := [maxCells]u8{}
	for i in 0 .. cells { current[i] = u8(input[6 + i]) }
	put_word(mut output, 0, i64(steps))
	for tick in 0 .. steps {
		for row in 0 .. rows {
			for col in 0 .. cols {
				site := row * cols + col
				if row == 0 || row == rows - 1 || col == 0 || col == cols - 1 { next[site] = 0; continue }
				if current[site] == 2 { next[site] = 0; continue }
				if current[site] == 0 {
					next[site] = if input[tape + tick * cells + site] < input[4] { u8(1) } else { u8(0) }
					continue
				}
				mut near_fire := false
				for r in max(0, row - 1) .. min(rows, row + 2) {
					for c in max(0, col - 1) .. min(cols, col + 2) {
						if (r != row || c != col) && current[r * cols + c] == 2 { near_fire = true }
					}
				}
				strike := input[tape + steps * cells + tick * cells + site]
				next[site] = if near_fire || strike < input[5] { u8(2) } else { u8(1) }
			}
		}
		mut totals := [3]i64{}
		for i in 0 .. cells { totals[int(next[i])]++ }
		base := 1 + 3 * tick
		for state in 0 .. 3 { put_word(mut output, base + state, totals[state]) }
		for i in 0 .. cells { current[i] = next[i] }
	}
	final_base := 1 + 3 * steps
	for i in 0 .. cells { put_word(mut output, final_base + i, i64(current[i])) }
	return i64(bytes)
}
