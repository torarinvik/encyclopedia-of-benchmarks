/// Constraint propagation with hidden and naked singles plus MRV search.
const SUDOKU_CELLS: usize = 81;
const ALL_DIGITS: u16 = 0x03FE;

fn isSingle(candidates: u16) bool {
    return candidates != 0 and (candidates & (candidates - 1)) == 0;
}

fn eliminate(candidates: *[SUDOKU_CELLS]u16, cell: usize, removed: u16) bool {
    if ((candidates[cell] & removed) == 0) return true;
    candidates[cell] &= ~removed;
    const remaining = candidates[cell];
    if (remaining == 0) return false;

    if (isSingle(remaining)) {
        const row = cell / 9;
        const column = cell % 9;
        for (0..SUDOKU_CELLS) |peer| {
            if (peer == cell) continue;
            const peer_row = peer / 9;
            const peer_column = peer % 9;
            const shares_row = row == peer_row;
            const shares_column = column == peer_column;
            const shares_box = row / 3 == peer_row / 3 and column / 3 == peer_column / 3;
            if ((shares_row or shares_column or shares_box) and
                !eliminate(candidates, peer, remaining)) return false;
        }
    }

    const row = cell / 9;
    const column = cell % 9;
    const box_row = row / 3 * 3;
    const box_column = column / 3 * 3;
    for (0..3) |unit| {
        var only_place: usize = 0;
        var place_count: usize = 0;
        for (0..9) |offset| {
            const place = if (unit == 0) row * 9 + offset else if (unit == 1)
                offset * 9 + column
            else
                (box_row + offset / 3) * 9 + box_column + offset % 3;
            if ((candidates[place] & removed) != 0) {
                only_place = place;
                place_count += 1;
            }
        }
        if (place_count == 0) return false;
        if (place_count == 1 and !assign(candidates, only_place, removed)) return false;
    }
    return true;
}

fn assign(candidates: *[SUDOKU_CELLS]u16, cell: usize, selected: u16) bool {
    if ((candidates[cell] & selected) == 0) return false;
    var digit: usize = 1;
    while (digit <= 9) : (digit += 1) {
        const bit: u16 = @as(u16, 1) << @intCast(digit);
        if (bit != selected and (candidates[cell] & bit) != 0) {
            if (!eliminate(candidates, cell, bit)) return false;
        }
    }
    return true;
}

fn search(candidates: *[SUDOKU_CELLS]u16) bool {
    var best_cell: usize = SUDOKU_CELLS;
    var best_count: usize = 10;
    for (0..SUDOKU_CELLS) |cell| {
        const count: usize = @intCast(@popCount(candidates[cell]));
        if (count == 0) return false;
        if (count > 1 and count < best_count) {
            best_cell = cell;
            best_count = count;
        }
    }
    if (best_cell == SUDOKU_CELLS) return true;

    const choices = candidates[best_cell];
    var digit: usize = 1;
    while (digit <= 9) : (digit += 1) {
        const bit: u16 = @as(u16, 1) << @intCast(digit);
        if ((choices & bit) == 0) continue;
        var branch = candidates.*;
        if (assign(&branch, best_cell, bit) and search(&branch)) {
            candidates.* = branch;
            return true;
        }
    }
    return false;
}

export fn sudoku_solver_mrv(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != SUDOKU_CELLS) return -1;
    var candidates: [SUDOKU_CELLS]u16 = @splat(ALL_DIGITS);
    for (0..SUDOKU_CELLS) |cell| {
        const value = values[cell];
        if (value < 0 or value > 9) return -1;
        if (value != 0) {
            const bit: u16 = @as(u16, 1) << @intCast(value);
            if (!assign(&candidates, cell, bit)) return -1;
        }
    }
    if (!search(&candidates)) return -1;
    if (output == null or output_capacity < 4 * SUDOKU_CELLS) return -2;
    for (0..SUDOKU_CELLS) |cell| {
        var digit: usize = 1;
        while (digit <= 9) : (digit += 1) {
            if ((candidates[cell] & (@as(u16, 1) << @intCast(digit))) != 0) break;
        }
        output[cell * 4] = @intCast(digit);
        output[cell * 4 + 1] = 0;
        output[cell * 4 + 2] = 0;
        output[cell * 4 + 3] = 0;
    }
    return SUDOKU_CELLS;
}
