module rle_lcs_block_dp;

// Run-length-native LCS by run-pair blocks and boundary propagation.
long rle_lcs_block_dp(long* packed, usz length) @export("rle_lcs_block_dp") {
    if (packed == null || length < 4 || length > 18) return -1;
    long left_count_value = packed[0];
    if (left_count_value < 1 || left_count_value > 4) return -1;
    usz left_count = (usz)left_count_value;
    usz right_count_index = 1 + 2 * left_count;
    if (right_count_index >= length) return -1;
    long right_count_value = packed[right_count_index];
    if (right_count_value < 1 || right_count_value > 4 ||
        length != right_count_index + 1 + 2 * (usz)right_count_value) return -1;
    usz right_count = (usz)right_count_value;
    long[4] left_symbol, left_size, right_symbol, right_size;
    usz left_total = 0, right_total = 0;
    for (usz run = 0; run < left_count; run++) {
        long symbol = packed[1 + 2 * run], size = packed[2 + 2 * run];
        if (symbol < 0 || symbol > 3 || size < 1 || size > 8) return -1;
        left_total += (usz)size;
        if (left_total > 16) return -1;
        left_symbol[run] = symbol; left_size[run] = size;
    }
    for (usz run = 0; run < right_count; run++) {
        long symbol = packed[right_count_index + 1 + 2 * run];
        long size = packed[right_count_index + 2 + 2 * run];
        if (symbol < 0 || symbol > 3 || size < 1 || size > 8) return -1;
        right_total += (usz)size;
        if (right_total > 16) return -1;
        right_symbol[run] = symbol; right_size[run] = size;
    }
    long[4][9] bottom = zeroed, next_bottom = zeroed;
    for (usz i = 0; i < left_count; i++) {
        long[9] left_boundary = zeroed;
        for (usz j = 0; j < right_count; j++) {
            usz rows = (usz)left_size[i], columns = (usz)right_size[j];
            long[9] previous, current, right_boundary;
            for (usz column = 0; column <= columns; column++) previous[column] = bottom[j][column];
            right_boundary[0] = previous[columns];
            for (usz row = 1; row <= rows; row++) {
                current[0] = left_boundary[row];
                for (usz column = 1; column <= columns; column++) {
                    if (left_symbol[i] == right_symbol[j]) current[column] = previous[column - 1] + 1;
                    else current[column] = previous[column] > current[column - 1] ? previous[column] : current[column - 1];
                }
                right_boundary[row] = current[columns];
                for (usz column = 0; column <= columns; column++) previous[column] = current[column];
            }
            for (usz column = 0; column <= columns; column++) next_bottom[j][column] = previous[column];
            for (usz row = 0; row <= rows; row++) left_boundary[row] = right_boundary[row];
        }
        for (usz j = 0; j < right_count; j++)
            for (usz column = 0; column <= (usz)right_size[j]; column++) bottom[j][column] = next_bottom[j][column];
    }
    return bottom[right_count - 1][(usz)right_size[right_count - 1]];
}
