#include <stdint.h>

int64_t problem15_dp(int64_t grid_size)
{
    if (grid_size < 0 || grid_size > 20) return -1;
    int64_t counts[21][21];
    for (int64_t row = 0; row <= grid_size; ++row)
        for (int64_t column = 0; column <= grid_size; ++column)
            counts[row][column] = 1;
    for (int64_t row = 1; row <= grid_size; ++row)
        for (int64_t column = 1; column <= grid_size; ++column)
            counts[row][column] = counts[row - 1][column] + counts[row][column - 1];
    return counts[grid_size][grid_size];
}
