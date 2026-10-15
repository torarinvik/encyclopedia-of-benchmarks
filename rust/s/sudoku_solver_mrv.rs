/// Sudoku constraint propagation with naked/hidden singles and MRV search.
const SUDOKU_CELLS: usize = 81;
const ALL_DIGITS: u16 = 0x03FE;

fn is_single(candidates: u16) -> bool {
    candidates != 0 && candidates & (candidates - 1) == 0
}

fn digit_for(candidate: u16) -> u32 {
    let mut digit = 1;
    while candidate & (1u16 << digit) == 0 { digit += 1; }
    digit
}

fn eliminate(candidates: &mut [u16; SUDOKU_CELLS], cell: usize, removed: u16) -> bool {
    if candidates[cell] & removed == 0 { return true; }
    candidates[cell] &= !removed;
    let remaining = candidates[cell];
    if remaining == 0 { return false; }

    if is_single(remaining) {
        for peer in 0..SUDOKU_CELLS {
            if peer == cell { continue; }
            let row = cell / 9;
            let column = cell % 9;
            let peer_row = peer / 9;
            let peer_column = peer % 9;
            let shares_row = row == peer_row;
            let shares_column = column == peer_column;
            let shares_box = row / 3 == peer_row / 3 && column / 3 == peer_column / 3;
            if (shares_row || shares_column || shares_box) &&
                !eliminate(candidates, peer, remaining) { return false; }
        }
    }

    let row = cell / 9;
    let column = cell % 9;
    let box_row = row / 3 * 3;
    let box_column = column / 3 * 3;
    for unit in 0..3 {
        let mut only_place = 0;
        let mut place_count = 0;
        for offset in 0..9 {
            let place = if unit == 0 {
                row * 9 + offset
            } else if unit == 1 {
                offset * 9 + column
            } else {
                (box_row + offset / 3) * 9 + box_column + offset % 3
            };
            if candidates[place] & removed != 0 {
                only_place = place;
                place_count += 1;
            }
        }
        if place_count == 0 { return false; }
        if place_count == 1 && !assign(candidates, only_place, removed) { return false; }
    }
    true
}

fn assign(candidates: &mut [u16; SUDOKU_CELLS], cell: usize, selected: u16) -> bool {
    if candidates[cell] & selected == 0 { return false; }
    let mut other = candidates[cell] & !selected;
    while other != 0 {
        let bit = other & other.wrapping_neg();
        other &= !bit;
        if !eliminate(candidates, cell, bit) { return false; }
    }
    true
}

fn search(candidates: &mut [u16; SUDOKU_CELLS]) -> bool {
    let mut best_cell = SUDOKU_CELLS;
    let mut best_count = 10;
    for cell in 0..SUDOKU_CELLS {
        let mut count = 0;
        let mut bits = candidates[cell];
        while bits != 0 {
            count += 1;
            bits &= bits - 1;
        }
        if count == 0 { return false; }
        if count > 1 && count < best_count {
            best_cell = cell;
            best_count = count;
        }
    }
    if best_cell == SUDOKU_CELLS { return true; }

    let choices = candidates[best_cell];
    for digit in 1..=9 {
        let bit = 1u16 << digit;
        if choices & bit == 0 { continue; }
        let mut branch = *candidates;
        if assign(&mut branch, best_cell, bit) && search(&mut branch) {
            *candidates = branch;
            return true;
        }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn sudoku_solver_mrv(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length != SUDOKU_CELLS { return -1; }
    let mut candidates = [ALL_DIGITS; SUDOKU_CELLS];
    for cell in 0..SUDOKU_CELLS {
        let value = *values.add(cell);
        if !(0..=9).contains(&value) { return -1; }
    }
    for cell in 0..SUDOKU_CELLS {
        let value = *values.add(cell);
        if value != 0 && !assign(&mut candidates, cell, 1u16 << (value as u32)) { return -1; }
    }
    if !search(&mut candidates) { return -1; }
    if output.is_null() || output_capacity < 4 * SUDOKU_CELLS { return -2; }
    for cell in 0..SUDOKU_CELLS {
        let digit = digit_for(candidates[cell]).to_le_bytes();
        for (byte, value) in digit.iter().enumerate() {
            *output.add(cell * 4 + byte) = *value;
        }
    }
    SUDOKU_CELLS as i64
}
