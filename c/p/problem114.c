#include <stdint.h>

enum { MAX_LENGTH = 50 };

int64_t problem114(int64_t length)
{
    if (length < 0 || length > MAX_LENGTH) return -1;
    int64_t ways[MAX_LENGTH + 1];
    for (int64_t index = 0; index <= length; ++index) ways[index] = 1;
    for (int64_t row_length = 3; row_length <= length; ++row_length) {
        for (int64_t block_length = 3; block_length <= row_length; ++block_length) {
            for (int64_t block_start = 0; block_start < row_length - block_length; ++block_start)
                ways[row_length] += ways[row_length - block_start - block_length - 1];
            ++ways[row_length];
        }
    }
    return ways[length];
}
