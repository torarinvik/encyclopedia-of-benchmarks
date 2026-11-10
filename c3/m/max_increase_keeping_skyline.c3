module max_increase_keeping_skyline;

const usz MAX_GRID_SIZE = 50;

// Return the total allowable increase while preserving row and column skylines.
fn long max_increase_keeping_skyline(long* values, usz length) @export("max_increase_keeping_skyline") {
    if (values == null || length < 2 || length > 1 + MAX_GRID_SIZE * MAX_GRID_SIZE) return -1;
    if (values[0] < 2 || (usz)values[0] > MAX_GRID_SIZE) return -1;
    usz size = (usz)values[0];
    if (length != 1 + size * size) return -1;

    char[MAX_GRID_SIZE] row_max = {};
    char[MAX_GRID_SIZE] column_max = {};
    ulong tallest = 0;
    uint height_sum = 0;
    for (usz row = 0; row < size; row++) {
        char row_tallest = 0;
        usz start = 1 + row * size;
        for (usz column = 0; column < size; column++) {
            ulong value = (ulong)values[start + column];
            tallest = value > tallest ? value : tallest;
            height_sum += (uint)value;
            char height = (char)value;
            row_tallest = height > row_tallest ? height : row_tallest;
            column_max[column] = height > column_max[column] ? height : column_max[column];
        }
        row_max[row] = row_tallest;
    }
    if (tallest > 100) return -1;

    uint skyline_sum = 0;
    if (size <= 10) {
        for (usz row = 0; row < size; row++) {
            char row_height = row_max[row];
            for (usz column = 0; column < size; column++) {
                char column_height = column_max[column];
                skyline_sum += (uint)(row_height < column_height ? row_height : column_height);
            }
        }
    } else {
        char[101] row_counts = {};
        char[101] column_counts = {};
        char lowest = 100;
        for (usz index = 0; index < size; index++) {
            lowest = row_max[index] < lowest ? row_max[index] : lowest;
            lowest = column_max[index] < lowest ? column_max[index] : lowest;
            row_counts[row_max[index]]++;
            column_counts[column_max[index]]++;
        }
        uint rows_above = (uint)size;
        uint columns_above = (uint)size;
        skyline_sum = rows_above * columns_above * lowest;
        for (usz height = lowest; height < tallest; height++) {
            rows_above -= row_counts[height];
            columns_above -= column_counts[height];
            skyline_sum += rows_above * columns_above;
        }
    }
    return (long)(skyline_sum - height_sum);
}
