// Zhang-Suen binary image thinning with simultaneous phase deletions.
module zhang_suen_thinning

const max_rows = 32
const max_columns = 32
const max_cells = 1024
const max_parseable_input_length = 1027

fn zst_thin_phase(mut image []u8, mut marked []u8, rows int, columns int,
        second_phase bool) bool {
	cells := rows * columns
	for index in 0 .. cells { marked[index] = 0 }
	mut changed := false
	for row in 1 .. rows - 1 {
		for column in 1 .. columns - 1 {
			index := row * columns + column
			if image[index] == 0 { continue }
			p2 := image[index - columns]
			p3 := image[index - columns + 1]
			p4 := image[index + 1]
			p5 := image[index + columns + 1]
			p6 := image[index + columns]
			p7 := image[index + columns - 1]
			p8 := image[index - 1]
			p9 := image[index - columns - 1]
			ring := [9]u8{p2, p3, p4, p5, p6, p7, p8, p9, p2}
			mut black_neighbors := 0
			mut transitions := 0
			for neighbor in 0 .. 8 {
				black_neighbors += int(ring[neighbor])
				if ring[neighbor] == 0 && ring[neighbor + 1] == 1 { transitions++ }
			}
			if black_neighbors < 2 || black_neighbors > 6 || transitions != 1 { continue }
			blocked := if second_phase {
				(p2 != 0 && p4 != 0 && p8 != 0) || (p2 != 0 && p6 != 0 && p8 != 0)
			} else {
				(p2 != 0 && p4 != 0 && p6 != 0) || (p4 != 0 && p6 != 0 && p8 != 0)
			}
			if blocked { continue }
			marked[index] = 1
			changed = true
		}
	}
	if changed {
		for index in 0 .. cells {
			if marked[index] != 0 { image[index] = 0 }
		}
	}
	return changed
}

@[export: 'zhang_suen_thinning']
pub fn zhang_suen_thinning(input &i64, length usize, output &u8,
		output_capacity usize) i64 {
	if length < 3 || length > max_parseable_input_length { return -1 }
	unsafe {
		rows_value := input[0]
		columns_value := input[1]
		if rows_value < 1 || rows_value > max_rows || columns_value < 1 || columns_value > max_columns {
			return -1
		}
		rows := int(rows_value)
		columns := int(columns_value)
		cells := rows * columns
		if length != usize(2 + cells) { return -1 }
		for index in 0 .. cells {
			if input[index + 2] != 0 && input[index + 2] != 1 { return -1 }
		}
		if output == nil || output_capacity < usize(cells) { return -2 }

		mut image := []u8{len: cells, init: 0}
		mut marked := []u8{len: cells, init: 0}
		for index in 0 .. cells { image[index] = u8(input[index + 2]) }
		for {
			first_changed := zst_thin_phase(mut image, mut marked, rows, columns, false)
			second_changed := zst_thin_phase(mut image, mut marked, rows, columns, true)
			if !first_changed && !second_changed { break }
		}
		for index in 0 .. cells { output[index] = image[index] }
		return i64(cells)
	}
}
