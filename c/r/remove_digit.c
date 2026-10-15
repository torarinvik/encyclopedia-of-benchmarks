#include <stdint.h>

#define INVALID_RESULT INT64_C(-1)
#define MIN_VALID_INPUT (INT64_MIN + INT64_C(1))

int64_t remove_digit(int64_t value)
{
    if (value == INT64_MIN || value < MIN_VALID_INPUT) return INVALID_RESULT;
    const int64_t magnitude = value < 0 ? -value : value;
    if (magnitude < 10) return INVALID_RESULT;

    int64_t place = 1;
    while (place <= magnitude / 10) place *= 10;
    int64_t maximum = 0;
    for (int64_t removed = 0; place > 0; ++removed, place /= 10) {
        int64_t candidate = 0;
        int64_t scan_place = 1;
        while (scan_place <= magnitude / 10) scan_place *= 10;
        int64_t position = 0;
        while (scan_place > 0) {
            const int64_t digit = (magnitude / scan_place) % 10;
            if (position != removed) candidate = candidate * 10 + digit;
            ++position;
            scan_place /= 10;
        }
        if (candidate > maximum) maximum = candidate;
    }
    return maximum;
}
