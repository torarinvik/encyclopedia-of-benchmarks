#include <stdint.h>

int64_t buzz_number(int64_t n)
{
    if (n % 7 == 0) return 1;
    if (n >= 0 && n % 10 == 7) return 1;
    return 0;
}
