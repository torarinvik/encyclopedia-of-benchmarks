module count_negative_numbers_in_sorted_matrix;

const usz MAX_CELLS = 512;

fn long count_negative_numbers_in_sorted_matrix(long* input, usz length) @export("count_negative_numbers_in_sorted_matrix")
{
    if (input == null || length < 3 || length > MAX_CELLS + 2) return -1;
    long rows_value = input[0];
    long columns_value = input[1];
    if (rows_value < 1 || rows_value > (long)MAX_CELLS || columns_value < 1 || columns_value > (long)MAX_CELLS) return -1;
    usz rows = (usz)rows_value;
    usz columns = (usz)columns_value;
    if (rows * columns > MAX_CELLS || length != 2 + rows * columns) return -1;

    usz nonnegative = 0;
    usz bound = columns;
    for (usz row = 0; row < rows; row += 1) {
        usz left = 0;
        usz right = bound;
        while (left < right) {
            usz middle = left + (right - left) / 2;
            long value = input[2 + row * columns + middle];
            if (value >= 0) left = middle + 1;
            else right = middle;
        }
        bound = left;
        nonnegative += bound;
    }
    return (long)(rows * columns - nonnegative);
}
