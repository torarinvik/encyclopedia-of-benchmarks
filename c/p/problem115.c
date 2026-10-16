#include <stdint.h>

int64_t problem115(int64_t min_block_length)
{
    if (min_block_length < 1 || min_block_length > 100) return -1;
    int64_t ways[1024];
    for (int64_t i = 0; i < min_block_length; ++i) ways[i] = 1;
    for (int64_t n = min_block_length; n < 1024; ++n) {
        ways[n] = 1;
        for (int64_t block_length = min_block_length; block_length <= n; ++block_length) {
            for (int64_t block_start = 0; block_start < n - block_length; ++block_start)
                ways[n] += ways[n - block_start - block_length - 1];
            ++ways[n];
        }
        if (ways[n] > 1000000) return n;
    }
    return -1;
}
