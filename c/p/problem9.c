#include <stdint.h>

int64_t problem9(int64_t total)
{
    if (total < 3 || total > 1000) return -1;
    for (int64_t a = 1; a <= total / 3; ++a) {
        for (int64_t b = a + 1; 2 * b < total - a; ++b) {
            int64_t c = total - a - b;
            if (a * a + b * b == c * c) return a * b * c;
        }
    }
    return -1;
}
