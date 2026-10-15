module max_increase_keeping_skyline;

const usz MAX_GRID_SIZE = 50;

// Return the total allowable increase while preserving row and column skylines.
fn long max_increase_keeping_skyline(long* values, usz length) @export("max_increase_keeping_skyline") {
    if (values == null || length < 2 || length > 1 + MAX_GRID_SIZE * MAX_GRID_SIZE) return -1;
    if (values[0] < 2 || (usz)values[0] > MAX_GRID_SIZE) return -1;
    usz size = (usz)values[0];
    if (length != 1 + size * size) return -1;

    long[MAX_GRID_SIZE] row_max;
    long[MAX_GRID_SIZE] column_max;
    for (usz index = 0; index < MAX_GRID_SIZE; index++) {
        row_max[index] = 0;
        column_max[index] = 0;
    }
    for (usz row = 0; row < size; row++) {
        for (usz column = 0; column < size; column++) {
            long height = values[1 + row * size + column];
            if (height < 0 || height > 100) return -1;
            if (height > row_max[row]) row_max[row] = height;
            if (height > column_max[column]) column_max[column] = height;
        }
    }

    long total = 0;
    for (usz row = 0; row < size; row++) {
        for (usz column = 0; column < size; column++) {
            long height = values[1 + row * size + column];
            long skyline = row_max[row] < column_max[column] ? row_max[row] : column_max[column];
            total += skyline - height;
        }
    }
    return total;
}
