module rle_levenshtein_block_dp;

long rle_levenshtein_block_dp(long* packed, usz length) @export("rle_levenshtein_block_dp") {
    if (packed == null || length < 4 || length > 18 || packed[0] < 1 || packed[0] > 4) return -1;
    usz left_count = (usz)packed[0];
    usz right_index = 1 + 2 * left_count;
    if (right_index >= length || packed[right_index] < 1 || packed[right_index] > 4) return -1;
    usz right_count = (usz)packed[right_index];
    if (length != right_index + 1 + 2 * right_count) return -1;
    long[4] left_symbol, left_size, right_symbol, right_size;
    usz left_total = 0, right_total = 0;
    for (usz run = 0; run < left_count; run++) {
        long symbol = packed[1 + 2 * run], size = packed[2 + 2 * run];
        if (symbol < 0 || symbol > 3 || size < 1 || size > 8) return -1;
        left_total += (usz)size; if (left_total > 16) return -1;
        left_symbol[run] = symbol; left_size[run] = size;
    }
    for (usz run = 0; run < right_count; run++) {
        long symbol = packed[right_index + 1 + 2 * run], size = packed[right_index + 2 + 2 * run];
        if (symbol < 0 || symbol > 3 || size < 1 || size > 8) return -1;
        right_total += (usz)size; if (right_total > 16) return -1;
        right_symbol[run] = symbol; right_size[run] = size;
    }
    long[4][9] bottom = zeroed, next_bottom = zeroed;
    usz right_prefix = 0;
    for (usz j = 0; j < right_count; j++) {
        for (usz col = 0; col <= (usz)right_size[j]; col++) bottom[j][col] = (long)(right_prefix + col);
        right_prefix += (usz)right_size[j];
    }
    usz left_prefix = 0;
    for (usz i = 0; i < left_count; i++) {
        usz rows = (usz)left_size[i];
        long[9] left_boundary = zeroed;
        for (usz row = 0; row <= rows; row++) left_boundary[row] = (long)(left_prefix + row);
        for (usz j = 0; j < right_count; j++) {
            usz columns = (usz)right_size[j];
            long[9] previous, current, right_boundary;
            for (usz col = 0; col <= columns; col++) previous[col] = bottom[j][col];
            right_boundary[0] = previous[columns];
            long substitution = left_symbol[i] == right_symbol[j] ? 0 : 1;
            for (usz row = 1; row <= rows; row++) {
                current[0] = left_boundary[row];
                for (usz col = 1; col <= columns; col++) {
                    long deletion = previous[col] + 1, insertion = current[col - 1] + 1;
                    long replace = previous[col - 1] + substitution;
                    current[col] = deletion < insertion ? deletion : insertion;
                    if (replace < current[col]) current[col] = replace;
                }
                right_boundary[row] = current[columns];
                for (usz col = 0; col <= columns; col++) previous[col] = current[col];
            }
            for (usz col = 0; col <= columns; col++) next_bottom[j][col] = previous[col];
            for (usz row = 0; row <= rows; row++) left_boundary[row] = right_boundary[row];
        }
        for (usz j = 0; j < right_count; j++)
            for (usz col = 0; col <= (usz)right_size[j]; col++) bottom[j][col] = next_bottom[j][col];
        left_prefix += rows;
    }
    return bottom[right_count - 1][(usz)right_size[right_count - 1]];
}
