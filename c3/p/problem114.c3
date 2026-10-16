module problem114;

const long MAX_LENGTH = 50;

fn long problem114(long length) @export("problem114") {
    if (length < 0 || length > MAX_LENGTH) return -1;
    long[MAX_LENGTH + 1] ways;
    for (long index = 0; index <= length; index++) ways[index.usz()] = 1;
    for (long row_length = 3; row_length <= length; row_length++) {
        for (long block_length = 3; block_length <= row_length; block_length++) {
            for (long block_start = 0; block_start < row_length - block_length; block_start++)
                ways[row_length.usz()] += ways[(row_length - block_start - block_length - 1).usz()];
            ways[row_length.usz()]++;
        }
    }
    return ways[length.usz()];
}
