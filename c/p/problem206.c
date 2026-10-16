/* Search the pinned source's descending square-pattern candidates. */
#include <stdint.h>

#define PROBLEM206_START INT64_C(138902663)
#define PROBLEM206_MINIMUM INT64_C(101010103)

static int problem206_is_square_form(int64_t value)
{
    int64_t digit = 9;
    while (value > 0) {
        if (value % 10 != digit) return 0;
        value /= 100;
        --digit;
    }
    return 1;
}

int64_t problem206(int64_t unused)
{
    if (unused != 0) return -1;
    int64_t candidate = PROBLEM206_START;
    while (candidate >= PROBLEM206_MINIMUM) {
        if (problem206_is_square_form(candidate * candidate)) return candidate * 10;
        candidate -= candidate % 10 == 3 ? 6 : 4;
    }
    return -1;
}
