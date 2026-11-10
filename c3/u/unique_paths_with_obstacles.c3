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

    ulong[MAX_COLUMNS] paths = {};
    paths[0] = 1;
    ulong cells_seen = 0;
    ulong left = 0;
    usz index = 2;
    while (index < length) {
        left = 0;
        for (usz column = 0; column < columns; column++) {
            ulong obstacle = (ulong)input[index++];
            cells_seen |= obstacle;
            left = obstacle == 0 ? left + paths[column] : 0;
            paths[column] = left;
        }
    }
    if (cells_seen > 1) return -1;
    return (long)left;
}
