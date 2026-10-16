module minimum_path_sum;

fn long minimum_path_sum(long* values, usz length) @export("minimum_path_sum") {
    if (values == null || length < 2 || length > 66) return -9223372036854775807L - 1;
    long row_value = values[0], column_value = values[1];
    if (row_value < 1 || row_value > 8 || column_value < 1 || column_value > 8) return -9223372036854775807L - 1;
    usz rows = (usz)row_value, columns = (usz)column_value;
    if (length != 2 + rows * columns) return -9223372036854775807L - 1;
    long[8] costs;
    for (usz row = 0; row < rows; row++) {
        for (usz column = 0; column < columns; column++) {
            long cell = values[2 + row * columns + column];
            if (cell < 0 || cell > 1000) return -9223372036854775807L - 1;
            if (row == 0 && column == 0) costs[column] = cell;
            else if (row == 0) costs[column] = costs[column - 1] + cell;
            else if (column == 0) costs[column] += cell;
            else costs[column] = (costs[column - 1] < costs[column] ? costs[column - 1] : costs[column]) + cell;
        }
    }
    return costs[columns - 1];
}
