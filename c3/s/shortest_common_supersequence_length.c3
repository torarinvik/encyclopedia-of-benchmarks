module shortest_common_supersequence_length;

// Return the shortest common supersequence length of two packed ASCII sequences.
fn long shortest_common_supersequence_length(long* packed, usz length) @export("shortest_common_supersequence_length")
{
    if (packed == null || length < 2 || length > 512) return -1;
    long left_length = packed[0];
    long right_length = packed[1];
    if (left_length < 0 || left_length > 255 || right_length < 0 || right_length > 255 ||
        length != (usz)(2 + left_length + right_length)) return -1;
    for (usz index = 0; index < (usz)(left_length + right_length); index++) {
        if (packed[2 + index] < 0 || packed[2 + index] > 127) return -1;
    }

    usz rows = (usz)(left_length + 1);
    usz columns = (usz)(right_length + 1);
    long[65536] table;
    for (usz index = 0; index < 65536; index++) table[index] = 0;
    for (usz i = 1; i < rows; i++) {
        for (usz j = 1; j < columns; j++) {
            usz cell = i * columns + j;
            if (packed[1 + i] == packed[1 + (usz)left_length + j]) {
                table[cell] = table[(i - 1) * columns + j - 1] + 1;
            } else {
                long above = table[(i - 1) * columns + j];
                long left = table[i * columns + j - 1];
                table[cell] = above > left ? above : left;
            }
        }
    }
    return left_length + right_length - table[(rows - 1) * columns + columns - 1];
}
