#include <stdint.h>

int64_t problem117(int64_t length)
{
    if (length < 0 || length > 67) return -1;
    int64_t ways[68] = {0};
    ways[0] = 1;
    for (int64_t row = 1; row <= length; ++row) {
        ways[row] = ways[row - 1];
        if (row >= 2) ways[row] += ways[row - 2];
        if (row >= 3) ways[row] += ways[row - 3];
        if (row >= 4) ways[row] += ways[row - 4];
    }
    return ways[length];
}
