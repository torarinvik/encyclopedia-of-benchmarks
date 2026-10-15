module sudoku_solver_mrv

const sudoku_cell_count = 81
const all_digits = u16(0x03fe)

fn is_single(candidates u16) bool {
	return candidates != 0 && (candidates & (candidates - 1)) == 0
}

fn eliminate(mut candidates []u16, cell int, removed u16) bool {
	if candidates[cell] & removed == 0 { return true }
	candidates[cell] &= u16(~removed)
	remaining := candidates[cell]
	if remaining == 0 { return false }

	if is_single(remaining) {
		row := cell / 9
		column := cell % 9
		for peer in 0 .. sudoku_cell_count {
			if peer == cell { continue }
			peer_row := peer / 9
			peer_column := peer % 9
			shares_row := row == peer_row
			shares_column := column == peer_column
			shares_box := row / 3 == peer_row / 3 && column / 3 == peer_column / 3
			if (shares_row || shares_column || shares_box) &&
				!eliminate(mut candidates, peer, remaining) { return false }
		}
	}

	row := cell / 9
	column := cell % 9
	box_row := row / 3 * 3
	box_column := column / 3 * 3
	for unit in 0 .. 3 {
		mut only_place := 0
		mut place_count := 0
		for offset in 0 .. 9 {
			place := if unit == 0 { row * 9 + offset } else if unit == 1 {
				offset * 9 + column
			} else {
				(box_row + offset / 3) * 9 + box_column + offset % 3
			}
			if candidates[place] & removed != 0 {
				only_place = place
				place_count++
			}
		}
		if place_count == 0 { return false }
		if place_count == 1 && !assign(mut candidates, only_place, removed) { return false }
	}
	return true
}

fn assign(mut candidates []u16, cell int, selected u16) bool {
	if candidates[cell] & selected == 0 { return false }
	mut digit := 1
	for digit <= 9 {
		bit := u16(1 << digit)
		if bit != selected && candidates[cell] & bit != 0 {
			if !eliminate(mut candidates, cell, bit) { return false }
		}
		digit++
	}
	return true
}

fn search(mut candidates []u16) bool {
	mut best_cell := sudoku_cell_count
	mut best_count := 10
	for cell in 0 .. sudoku_cell_count {
		mut count := 0
		for digit in 1 .. 10 {
			if candidates[cell] & u16(1 << digit) != 0 { count++ }
		}
		if count == 0 { return false }
		if count > 1 && count < best_count {
			best_cell = cell
			best_count = count
		}
	}
	if best_cell == sudoku_cell_count { return true }

	for digit in 1 .. 10 {
		bit := u16(1 << digit)
		if candidates[best_cell] & bit == 0 { continue }
		mut branch := candidates.clone()
		if assign(mut branch, best_cell, bit) && search(mut branch) {
			for cell in 0 .. sudoku_cell_count { candidates[cell] = branch[cell] }
			return true
		}
	}
	return false
}

// Constraint propagation with hidden and naked singles plus MRV search.
@[export: 'sudoku_solver_mrv']
pub fn sudoku_solver_mrv(values &i64, length usize, output &u8,
		output_capacity usize) i64 {
	if values == nil || length != sudoku_cell_count { return -1 }
	unsafe {
		mut candidates := []u16{len: sudoku_cell_count, init: all_digits}
		for cell in 0 .. sudoku_cell_count {
			value := values[cell]
			if value < 0 || value > 9 { return -1 }
			if value != 0 && !assign(mut candidates, cell, u16(1 << int(value))) { return -1 }
		}
		if !search(mut candidates) { return -1 }
		if output == nil || output_capacity < 4 * sudoku_cell_count { return -2 }
		for cell in 0 .. sudoku_cell_count {
			mut digit := 1
			for digit <= 9 {
				if candidates[cell] & u16(1 << digit) != 0 { break }
				digit++
			}
			for byte in 0 .. 4 {
				output[cell * 4 + byte] = if byte == 0 { u8(digit) } else { 0 }
			}
		}
		return sudoku_cell_count
	}
}
