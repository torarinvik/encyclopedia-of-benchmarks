module problem18;

const usz MAX_ROWS = 15;
const usz MAX_VALUES = MAX_ROWS * (MAX_ROWS + 1) / 2;
const long VALUE_LIMIT = 1000000;

fn long problem18(long* input, usz length) @export("problem18") {
    if (input == null || length < 2 || length > MAX_VALUES + 1) return -1;
    long rows = input[0];
    if (rows < 1 || rows > (long)MAX_ROWS || length != (usz)(rows * (rows + 1) / 2) + 1) return -1;
    long[MAX_VALUES] best = {0};
    usz value_count = length - 1;
    for (usz index = 0; index < value_count; index++) {
        long value = input[index + 1];
        if (value < 0 || value > VALUE_LIMIT) return -1;
        best[index] = value;
    }
    for (long row = rows - 1; row > 0; row--) {
        usz parent_start = (usz)((row - 1) * row / 2);
        usz child_start = (usz)(row * (row + 1) / 2);
        for (long column = 0; column < row; column++) {
            usz parent = parent_start + (usz)column;
            usz child = child_start + (usz)column;
            long left = best[child];
            long right = best[child + 1];
            best[parent] += left > right ? left : right;
        }
    }
    return best[0];
}
