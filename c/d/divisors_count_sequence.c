#include <stdint.h>

#define MAX_INDEX INT64_C(9999)

int64_t divisors_count_sequence(int64_t index)
{
    if (index < 0 || index > MAX_INDEX) return -1;
    const int64_t n = index + 1;
    if (n == 1) return 1;
    int64_t count = 2;
    for (int64_t k = 2; k < n; ++k) {
        if (n % k == 0) ++count;
    }
    return count;
}
