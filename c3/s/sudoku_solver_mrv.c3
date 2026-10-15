module sudoku_solver_mrv;

const SUDOKU_CELLS = 81;
const ALL_DIGITS = (ushort)0x03FE;

fn bool is_single(ushort candidates) {
    return candidates != 0 && (candidates & (ushort)(candidates - 1)) == 0;
}

fn bool assign(ushort* candidates, usz cell, ushort selected);

fn bool eliminate(ushort* candidates, usz cell, ushort removed) {
    if ((candidates[cell] & removed) == 0) return true;
    candidates[cell] = (ushort)(candidates[cell] & (ushort)~removed);
    ushort remaining = candidates[cell];
    if (remaining == 0) return false;

    if (is_single(remaining)) {
        for (usz peer = 0; peer < SUDOKU_CELLS; peer++) {
            if (peer == cell) continue;
            usz row = cell / 9, column = cell % 9;
            usz peer_row = peer / 9, peer_column = peer % 9;
            bool shares_row = row == peer_row;
            bool shares_column = column == peer_column;
            bool shares_box = row / 3 == peer_row / 3 && column / 3 == peer_column / 3;
            if ((shares_row || shares_column || shares_box) &&
                !eliminate(candidates, peer, remaining)) return false;
        }
    }

    usz row = cell / 9, column = cell % 9;
    usz box_row = row / 3 * 3, box_column = column / 3 * 3;
    for (usz unit = 0; unit < 3; unit++) {
        usz only_place = 0;
        usz place_count = 0;
        for (usz offset = 0; offset < 9; offset++) {
            usz place;
            if (unit == 0) place = row * 9 + offset;
            else if (unit == 1) place = offset * 9 + column;
            else place = (box_row + offset / 3) * 9 + box_column + offset % 3;
            if ((candidates[place] & removed) != 0) {
                only_place = place;
                place_count++;
            }
        }
        if (place_count == 0) return false;
        if (place_count == 1 && !assign(candidates, only_place, removed)) return false;
    }
    return true;
}

fn bool assign(ushort* candidates, usz cell, ushort selected) {
    if ((candidates[cell] & selected) == 0) return false;
    ushort other = (ushort)(candidates[cell] & (ushort)~selected);
    while (other != 0) {
        ushort bit = (ushort)(other & (ushort)(0U - other));
        other = (ushort)(other & (ushort)~bit);
        if (!eliminate(candidates, cell, bit)) return false;
    }
    return true;
}

fn bool search(ushort* candidates) {
    usz best_cell = SUDOKU_CELLS;
    uint best_count = 10;
    for (usz cell = 0; cell < SUDOKU_CELLS; cell++) {
        uint count = 0;
        for (ushort bits = candidates[cell]; bits != 0; bits = (ushort)(bits & (ushort)(bits - 1))) count++;
        if (count == 0) return false;
        if (count > 1 && count < best_count) {
            best_cell = cell;
            best_count = count;
        }
    }
    if (best_cell == SUDOKU_CELLS) return true;

    ushort choices = candidates[best_cell];
    for (uint digit = 1; digit <= 9; digit++) {
        ushort bit = (ushort)(1U << digit);
        if ((choices & bit) == 0) continue;
        ushort[81] branch;
        for (usz cell = 0; cell < SUDOKU_CELLS; cell++) branch[cell] = candidates[cell];
        if (assign(&branch[0], best_cell, bit) && search(&branch[0])) {
            for (usz cell = 0; cell < SUDOKU_CELLS; cell++) candidates[cell] = branch[cell];
            return true;
        }
    }
    return false;
}

fn long sudoku_solver_mrv(long* values, usz length, char* output, usz output_capacity)
    @export("sudoku_solver_mrv")
{
    if (values == null || length != SUDOKU_CELLS) return -1;
    ushort[81] candidates;
    for (usz cell = 0; cell < SUDOKU_CELLS; cell++) {
        if (values[cell] < 0 || values[cell] > 9) return -1;
        candidates[cell] = ALL_DIGITS;
    }
    for (usz cell = 0; cell < SUDOKU_CELLS; cell++) {
        if (values[cell] != 0 && !assign(&candidates[0], cell, (ushort)(1U << (uint)values[cell]))) return -1;
    }
    if (!search(&candidates[0])) return -1;
    if (output == null || output_capacity < 4 * SUDOKU_CELLS) return -2;
    for (usz cell = 0; cell < SUDOKU_CELLS; cell++) {
        uint digit = 1;
        while ((candidates[cell] & (ushort)(1U << digit)) == 0) digit++;
        for (usz byte = 0; byte < 4; byte++) output[cell * 4 + byte] = (char)((digit >> (byte * 8)) & 255);
    }
    return SUDOKU_CELLS;
}
