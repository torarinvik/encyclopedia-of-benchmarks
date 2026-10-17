module search_in_arow_and_col_wise_sorted_matrix;

const usz MAX_DIMENSION = 63;
const usz MAX_INPUT_VALUES = 2 + MAX_DIMENSION * MAX_DIMENSION;

fn void write_i32_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 4; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits = bits >> 8;
    }
}

fn long search_in_arow_and_col_wise_sorted_matrix(long* input, usz length, char* output, usz capacity)
    @export("search_in_arow_and_col_wise_sorted_matrix") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    long n_value = input[0];
    long target = input[1];
    if (n_value < 1 || n_value > (long)MAX_DIMENSION || target < -2147483648 || target > 2147483647) return -1;
    usz n = (usz)n_value;
    if (length != 2 + n * n) return -1;

    usz target_count = 0;
    for (usz row = 0; row < n; row++) {
        for (usz column = 0; column < n; column++) {
            usz index = row * n + column;
            long value = input[2 + index];
            if (value < -2147483648 || value > 2147483647) return -1;
            if (column > 0 && value < input[2 + index - 1]) return -1;
            if (row > 0 && value < input[2 + index - n]) return -1;
            if (value == target) {
                target_count++;
                if (target_count > 1) return -1;
            }
        }
    }

    usz row = 0;
    long column = (long)n - 1;
    long result_row = -1, result_column = -1, found = 0;
    while (row < n && column >= 0) {
        long value = input[2 + row * n + (usz)column];
        if (value == target) {
            result_row = (long)row;
            result_column = column;
            found = 1;
            break;
        }
        if (target > value) row++;
        else column--;
    }

    if (output == null || capacity < 8) return -2;
    char buffer[8] = {0};
    write_i32_le(buffer, 0, result_row);
    write_i32_le(buffer, 4, result_column);
    for (usz index = 0; index < 8; index++) output[index] = buffer[index];
    return found;
}
