/* Find the first bad version with a lower-bound binary search. */
#include <stdint.h>

int64_t first_bad_version(uint64_t version_count, uint64_t first_bad)
{
    if (version_count == 0 || version_count > UINT64_C(2147483647) ||
        first_bad == 0 || first_bad > version_count) return -1;

    uint64_t low = 1;
    uint64_t high = version_count;
    while (low < high) {
        const uint64_t middle = low + (high - low) / 2;
        if (middle >= first_bad) high = middle;
        else low = middle + 1;
    }
    return (int64_t)low;
}
