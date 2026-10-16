#include <stdint.h>

static int is_bouncy(int64_t value)
{
    int increasing = 0, decreasing = 0;
    int64_t previous = value % 10;
    value /= 10;
    while (value > 0) {
        const int64_t digit = value % 10;
        if (digit < previous) increasing = 1;
        if (digit > previous) decreasing = 1;
        previous = digit;
        value /= 10;
    }
    return increasing && decreasing;
}

int64_t problem112(int64_t percent)
{
    if (percent < 1 || percent > 99) return -1;
    int64_t bouncy = 0;
    for (int64_t n = 1; ; ++n) {
        if (is_bouncy(n)) ++bouncy;
        if (bouncy * 100 >= percent * n) return n;
    }
}
