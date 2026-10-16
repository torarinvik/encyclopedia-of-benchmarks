module minesweeper

const max_dim = 32
const max_cells = max_dim * max_dim
const max_output = 8 + 8 * max_cells

fn write_i64(mut output &u8, position int, value i64) int {
	bits := u64(value)
	unsafe { for i in 0 .. 8 { output[position + i] = u8((bits >> (8 * i)) & 255) } }
	return position + 8
}

@[export: 'minesweeper']
pub fn minesweeper(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(2 + max_cells) { return -1 }
	unsafe {
		rows_value, cols_value := input[0], input[1]
		if rows_value < 1 || rows_value > max_dim || cols_value < 1 || cols_value > max_dim { return -1 }
		rows, cols := int(rows_value), int(cols_value)
		count := rows * cols
		if length != usize(2 + count) { return -1 }
		mut cells := [max_cells]u8{}
		for i in 0 .. count { if input[2 + i] != 0 && input[2 + i] != 1 { return -1 }; cells[i] = u8(input[2 + i]) }
		mut neighbors := [max_cells]i64{}
		for row in 0 .. rows {
			for col in 0 .. cols {
				mut mines := i64(0)
				for dr in -1 .. 2 { for dc in -1 .. 2 {
					if dr == 0 && dc == 0 { continue }
					nr, nc := row + dr, col + dc
					if nr >= 0 && nr < rows && nc >= 0 && nc < cols && cells[nr * cols + nc] == 1 { mines++ }
				} }
				neighbors[row * cols + col] = mines
			}
		}
		needed := 8 + 8 * count
		if output == nil || output_capacity < usize(needed) { return -2 }
		mut payload := [max_output]u8{}
		mut written := write_i64(mut payload[0], 0, i64(count))
		for i in 0 .. count { written = write_i64(mut payload[0], written, neighbors[i]) }
		for i in 0 .. written { output[i] = payload[i] }
		return i64(written)
	}
}
