module problem82;

const usz MAX_ROWS = 80;
const usz MAX_COLUMNS = 80;
const long MAX_CELL_VALUE = 9999;

fn long problem82(long* input, usz length) @export("problem82") {
    if (input == null || length < 3) return -1;
    long row_value = input[0], column_value = input[1];
    if (row_value < 1 || row_value > MAX_ROWS.long() || column_value < 1 || column_value > MAX_COLUMNS.long()) return -1;
    usz rows = (usz)row_value, columns = (usz)column_value;
    if (length != 2 + rows * columns) return -1;
    for (usz index = 2; index < length; index++)
        if (input[index] < 0 || input[index] > MAX_CELL_VALUE) return -1;

    long[80] costs;
    for (usz row = 0; row < rows; row++) costs[row] = input[2 + row * columns];
    for (usz column = 1; column < columns; column++) {
        usz offset = 2 + column;
        for (usz row = 0; row < rows; row++) costs[row] += input[offset + row * columns];
        for (usz row = 1; row < rows; row++) {
            long from_above = costs[row - 1] + input[offset + row * columns];
            if (from_above < costs[row]) costs[row] = from_above;
        }
        usz row = rows - 1;
        while (row > 0) {
            long from_below = costs[row] + input[offset + (row - 1) * columns];
            if (from_below < costs[row - 1]) costs[row - 1] = from_below;
            row--;
        }
    }
    long best = costs[0];
    for (usz row = 1; row < rows; row++) if (costs[row] < best) best = costs[row];
    return best;
}
