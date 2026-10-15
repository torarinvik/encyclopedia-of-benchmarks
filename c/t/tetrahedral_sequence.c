#include <stdint.h>

#define MAX_INDEX INT64_C(3810777)

int64_t tetrahedral_sequence(int64_t index)
{
    if (index < 0 || index > MAX_INDEX) return -1;
    int64_t a = index;
    int64_t b = index + 1;
    int64_t c = index + 2;
    if (a % 2 == 0) a /= 2;
    else if (b % 2 == 0) b /= 2;
    else c /= 2;
    if (a % 3 == 0) a /= 3;
    else if (b % 3 == 0) b /= 3;
    else c /= 3;
    return a * b * c;
}
