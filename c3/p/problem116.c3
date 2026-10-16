// Count single-color block replacements for lengths two, three, and four.
module problem116;

const long MAX_LENGTH = 91;

fn long problem116(long length) @export("problem116") {
    if (length > MAX_LENGTH) return -1;
    if (length < 0) return -1;
    long[276] ways = {0};
    for (long row_length = 0; row_length <= length; row_length++) {
        for (long tile_length = 2; tile_length < 5; tile_length++) {
            long color = tile_length - 2;
            for (long tile_start = 0; tile_start < row_length - tile_length + 1; tile_start++) {
                long suffix = row_length - tile_start - tile_length;
                ways[row_length * 3 + color] += ways[suffix * 3 + color] + 1;
            }
        }
    }
    return ways[length * 3] + ways[length * 3 + 1] + ways[length * 3 + 2];
}
