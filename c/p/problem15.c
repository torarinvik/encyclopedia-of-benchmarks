#include <stdint.h>

int64_t problem15(int64_t grid_size)
{
    if (grid_size < 0 || grid_size > 20) return -1;
    int64_t paths = 1;
    for (int64_t step = 1; step <= grid_size; ++step)
        paths = paths * (grid_size + step) / step;
    return paths;
}
