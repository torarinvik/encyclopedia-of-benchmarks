module validate_sudoku_board;

fn long validate_sudoku_board(long* input, usz length, char* output, usz capacity) @export("validate_sudoku_board") {
    if (input == null || length != 81) return -1;
    for (usz i = 0; i < 81; i++) {
        long value = input[i];
        if (value != 46 && (value < 49 || value > 57)) return -1;
    }
    if (output == null || capacity < 1) return -2;
    uint[9] rows = {0}, columns = {0}, boxes = {0};
    bool valid = true;
    for (usz i = 0; i < 81; i++) {
        long value = input[i];
        if (value == 46) continue;
        usz row = i / 9, col = i % 9, box = (row / 3) * 3 + col / 3;
        uint bit = 1u << (uint)(value - 48);
        if ((rows[row] & bit) != 0 || (columns[col] & bit) != 0 || (boxes[box] & bit) != 0) valid = false;
        rows[row] |= bit; columns[col] |= bit; boxes[box] |= bit;
    }
    output[0] = (char)(valid ? 1 : 0);
    return 1;
}
