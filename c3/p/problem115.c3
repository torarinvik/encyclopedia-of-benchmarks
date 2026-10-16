module problem115;

fn long problem115(long min_block_length) @export("problem115") {
    if (min_block_length < 1 || min_block_length > 100) return -1;
    long[1024] ways;
    for (long i = 0; i < min_block_length; i++) ways[i] = 1;
    for (long n = min_block_length; n < 1024; n++) {
        ways[n] = 1;
        for (long block_length = min_block_length; block_length <= n; block_length++) {
            for (long block_start = 0; block_start < n - block_length; block_start++)
                ways[n] += ways[n - block_start - block_length - 1];
            ways[n]++;
        }
        if (ways[n] > 1000000) return n;
    }
    return -1;
}
