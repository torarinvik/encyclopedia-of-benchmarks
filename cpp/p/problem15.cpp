#include <cstdint>

extern "C" std::int64_t problem15(std::int64_t grid_size) noexcept
{
    if (grid_size < 0 || grid_size > 20) return -1;
    std::int64_t paths = 1;
    for (std::int64_t step = 1; step <= grid_size; ++step)
        paths = paths * (grid_size + step) / step;
    return paths;
}
