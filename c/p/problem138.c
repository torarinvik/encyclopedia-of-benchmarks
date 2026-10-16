#include <stdint.h>

int64_t problem138(int64_t count)
{
    if (count > 14) return -1;
    if (count <= 0) return 0;
    int64_t m = 2, l = 1, total = 0;
    for (int64_t i = 0; i < count; ++i) {
        const int64_t next_m = 9 * m + 20 * l;
        const int64_t next_l = 4 * m + 9 * l;
        m = next_m;
        l = next_l;
        total += l;
    }
    return total;
}
