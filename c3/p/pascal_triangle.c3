module pascal_triangle;

const usz MAX_ROWS = 30;
const long HASH_MOD = 1000000007;

fn long pascal_triangle_benchmark(long* values, usz length) @export("pascal_triangle_benchmark") {
    if (length != 1) return -1;
    long row_count_value = values[0];
    if (row_count_value < 0 || row_count_value > (long)MAX_ROWS) return -1;
    usz row_count = (usz)row_count_value;
    long[MAX_ROWS] row;
    row[0] = 1;
    long hash = 0;
    for (usz row_index = 0; row_index < row_count; row_index++) {
        usz column = row_index;
        while (column > 0) {
            row[column] += row[column - 1];
            column--;
        }
        for (usz col = 0; col <= row_index; col++) {
            hash = (hash * 31 + row[col] % HASH_MOD) % HASH_MOD;
        }
    }
    return hash;
}
