module sudoku_solver;

fn bool sudoku_search(long* board, ulong* rows, ulong* columns,
                      ulong* boxes, usz position) {
    while (position < 81 && board[position] != 0) position++;
    if (position == 81) return true;
    usz row = position / 9;
    usz column = position % 9;
    usz box = (row / 3) * 3 + column / 3;
    for (long digit = 1; digit <= 9; digit++) {
        ulong bit = (ulong)1 << digit;
        if ((rows[row] & bit) != 0 || (columns[column] & bit) != 0 || (boxes[box] & bit) != 0) continue;
        board[position] = digit;
        rows[row] |= bit; columns[column] |= bit; boxes[box] |= bit;
        if (sudoku_search(board, rows, columns, boxes, position + 1)) return true;
        board[position] = 0;
        rows[row] ^= bit; columns[column] ^= bit; boxes[box] ^= bit;
    }
    return false;
}

fn long sudoku_solver(long* values, usz length, char* output, usz output_capacity)
        @export("sudoku_solver") {
    if (length != 81 || values == null) return -1;
    long[81] board;
    ulong[9] rows;
    ulong[9] columns;
    ulong[9] boxes;
    for (usz index = 0; index < 9; index++) {
        rows[index] = 0; columns[index] = 0; boxes[index] = 0;
    }
    for (usz position = 0; position < 81; position++) {
        long digit = values[position];
        if (digit < 0 || digit > 9) return -1;
        board[position] = digit;
        if (digit == 0) continue;
        usz row = position / 9;
        usz column = position % 9;
        usz box = (row / 3) * 3 + column / 3;
        ulong bit = (ulong)1 << digit;
        if ((rows[row] & bit) != 0 || (columns[column] & bit) != 0 || (boxes[box] & bit) != 0) return -1;
        rows[row] |= bit; columns[column] |= bit; boxes[box] |= bit;
    }
    if (output_capacity < 324 || output == null) return -2;
    if (!sudoku_search(&board[0], &rows[0], &columns[0], &boxes[0], 0)) return -1;
    for (usz position = 0; position < 81; position++) {
        ulong bits = (ulong)board[position];
        for (usz byte = 0; byte < 4; byte++) {
            output[position * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
        }
    }
    return 81;
}
