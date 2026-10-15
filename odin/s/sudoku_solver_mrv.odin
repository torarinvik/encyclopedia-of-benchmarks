package sudoku_solver_mrv

import "core:c"

SUDOKU_CELLS :: 81
ALL_DIGITS :: u16(0x03FE)

is_single :: proc "contextless" (mask: u16) -> bool {
	return mask != 0 && (mask & (mask - 1)) == 0
}

digit_for :: proc "contextless" (candidate: u16) -> u32 {
	for digit := u32(1); digit <= 9; digit += 1 {
		if (candidate & (u16(1) << digit)) != 0 do return digit
	}
	return 0
}

propagate :: proc "contextless" (candidates: [^]u16, cell: int, mask: u16, assigning: bool) -> bool {
	if assigning {
		if (candidates[cell] & mask) == 0 do return false
		other := candidates[cell] & ~mask
		for digit := u32(1); digit <= 9; digit += 1 {
			bit := u16(1) << digit
			if (other & bit) != 0 && !propagate(candidates, cell, bit, false) do return false
		}
		return true
	}

	if (candidates[cell] & mask) == 0 do return true
	candidates[cell] &= ~mask
	remaining := candidates[cell]
	if remaining == 0 do return false
	if is_single(remaining) {
		for peer := 0; peer < SUDOKU_CELLS; peer += 1 {
			if peer == cell do continue
			row := cell / 9
			column := cell % 9
			peer_row := peer / 9
			peer_column := peer % 9
			shares_row := row == peer_row
			shares_column := column == peer_column
			shares_box := row / 3 == peer_row / 3 && column / 3 == peer_column / 3
			if (shares_row || shares_column || shares_box) && !propagate(candidates, peer, remaining, false) do return false
		}
	}

	row := cell / 9
	column := cell % 9
	box_row := row / 3 * 3
	box_column := column / 3 * 3
	for unit := 0; unit < 3; unit += 1 {
		only_place := 0
		place_count := 0
		for offset := 0; offset < 9; offset += 1 {
			place := 0
			if unit == 0 {
				place = row * 9 + offset
			} else if unit == 1 {
				place = offset * 9 + column
			} else {
				place = (box_row + offset / 3) * 9 + box_column + offset % 3
			}
			if (candidates[place] & mask) != 0 {
				only_place = place
				place_count += 1
			}
		}
		if place_count == 0 do return false
		if place_count == 1 && !propagate(candidates, only_place, mask, true) do return false
	}
	return true
}

search :: proc "contextless" (candidates: [^]u16) -> bool {
	best_cell := SUDOKU_CELLS
	best_count := 10
	for cell := 0; cell < SUDOKU_CELLS; cell += 1 {
		count := 0
		bits := candidates[cell]
		for bits != 0 {
			count += 1
			bits &= bits - 1
		}
		if count == 0 do return false
		if count > 1 && count < best_count {
			best_cell = cell
			best_count = count
		}
	}
	if best_cell == SUDOKU_CELLS do return true

	choices := candidates[best_cell]
	for digit := u32(1); digit <= 9; digit += 1 {
		bit := u16(1) << digit
		if (choices & bit) == 0 do continue
		branch: [SUDOKU_CELLS]u16
		for cell := 0; cell < SUDOKU_CELLS; cell += 1 {
			branch[cell] = candidates[cell]
		}
		if propagate(&branch[0], best_cell, bit, true) && search(&branch[0]) {
			for cell := 0; cell < SUDOKU_CELLS; cell += 1 {
				candidates[cell] = branch[cell]
			}
			return true
		}
	}
	return false
}

// Sudoku constraint propagation with naked/hidden singles and MRV search.
@(export)
sudoku_solver_mrv :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != SUDOKU_CELLS do return -1
	candidates: [SUDOKU_CELLS]u16
	for cell := 0; cell < SUDOKU_CELLS; cell += 1 {
		if values[cell] < 0 || values[cell] > 9 do return -1
		candidates[cell] = ALL_DIGITS
	}
	for cell := 0; cell < SUDOKU_CELLS; cell += 1 {
		value := values[cell]
		if value != 0 && !propagate(&candidates[0], cell, u16(1) << u64(value), true) do return -1
	}
	if !search(&candidates[0]) do return -1
	if output == nil || output_capacity < 4 * SUDOKU_CELLS do return -2
	for cell := 0; cell < SUDOKU_CELLS; cell += 1 {
		digit := digit_for(candidates[cell])
		for byte := 0; byte < 4; byte += 1 {
			output[cell * 4 + byte] = u8((digit >> (byte * 8)) & 0xFF)
		}
	}
	return SUDOKU_CELLS
}
