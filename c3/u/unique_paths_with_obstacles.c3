module unique_paths_with_obstacles;

const usz MAX_ROWS = 20;
const usz MAX_COLUMNS = 20;

// Count right/down paths through a packed obstacle grid.
fn long unique_paths_with_obstacles(long* input, usz length) @export("unique_paths_with_obstacles") {
    if (input == null || length < 2) { return -1; }
    long rows_value = input[0];
    long columns_value = input[1];
    if (rows_value < 1 || rows_value > 20 || columns_value < 1 || columns_value > 20) { return -1; }
    usz rows = (usz)rows_value;
    usz columns = (usz)columns_value;
    if (length != 2 + rows * columns) { return -1; }
    for (usz index = 2; index < length; index++) {
        if (input[index] != 0 && input[index] != 1) { return -1; }
    }

    long[20] paths;
    for (usz column = 0; column < columns; column++) { paths[column] = 0; }
    paths[0] = 1;
    for (usz row = 0; row < rows; row++) {
        for (usz column = 0; column < columns; column++) {
            long obstacle = input[2 + row * columns + column];
            if (obstacle == 1) { paths[column] = 0; }
            else if (column != 0) { paths[column] += paths[column - 1]; }
        }
    }
    return paths[columns - 1];
}
