#include <stdint.h>

static int is_prime(int64_t value)
{
    if (value < 2) return 0;
    for (int64_t factor = 2; factor <= value / factor; ++factor)
        if (value % factor == 0) return 0;
    return 1;
}

int64_t problem7(int64_t index)
{
    if (index < 1 || index > 10001) return -1;
    int64_t count = 0;
    int64_t candidate = 1;
    while (count < index) {
        ++candidate;
        if (is_prime(candidate)) ++count;
    }
    return candidate;
}
