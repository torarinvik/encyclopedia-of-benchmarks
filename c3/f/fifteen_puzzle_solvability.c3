module fifteen_puzzle_solvability;

const usz CELL_COUNT = 16;

fn long fifteen_puzzle_solvability(long* input, usz length)
        @export("fifteen_puzzle_solvability") {
    if (input == null || length != CELL_COUNT) return -1;

    long blank = -1;
    for (usz i = 0; i < CELL_COUNT; ++i) {
        if (input[i] < 0 || input[i] >= 16) return -1;
        for (usz j = 0; j < i; ++j) {
            if (input[i] == input[j]) return -1;
        }
        if (input[i] == 0) blank = (long)i;
    }
    if (blank < 0) return -1;

    long inversions = 0;
    for (usz i = 0; i < CELL_COUNT; ++i) {
        if (input[i] == 0) continue;
        for (usz j = i + 1; j < CELL_COUNT; ++j) {
            if (input[j] != 0 && input[i] > input[j]) ++inversions;
        }
    }
    long blank_row_from_top = blank / 4 + 1;
    return (inversions + blank_row_from_top) % 2 == 0 ? 1 : 0;
}
