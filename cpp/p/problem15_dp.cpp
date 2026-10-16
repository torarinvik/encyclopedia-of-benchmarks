#include <cstdint>

extern "C" std::int64_t problem15_dp(std::int64_t grid_size) noexcept
{
    if (grid_size < 0 || grid_size > 20) return -1;
    std::int64_t counts[21][21];
    for (std::int64_t row = 0; row <= grid_size; ++row)
        for (std::int64_t column = 0; column <= grid_size; ++column)
            counts[row][column] = 1;
    for (std::int64_t row = 1; row <= grid_size; ++row)
        for (std::int64_t column = 1; column <= grid_size; ++column)
            counts[row][column] = counts[row - 1][column] + counts[row][column - 1];
    return counts[grid_size][grid_size];
}
