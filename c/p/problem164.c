#include <stdint.h>

int64_t problem164(int64_t n_digits)
{
    if (n_digits < 0 || n_digits > 26) return -1;
    if (n_digits == 0) return 1;

    int64_t current[100] = {0};
    int64_t next[100] = {0};
    for (int64_t first = 1; first <= 9; ++first) current[first * 10] = 1;

    for (int64_t used = 1; used < n_digits; ++used) {
        for (int64_t index = 0; index < 100; ++index) next[index] = 0;
        for (int64_t previous = 0; previous <= 9; ++previous) {
            for (int64_t before_previous = 0; before_previous <= 9; ++before_previous) {
                const int64_t ways = current[previous * 10 + before_previous];
                const int64_t maximum_digit = 9 - previous - before_previous;
                for (int64_t digit = 0; digit <= maximum_digit; ++digit)
                    next[digit * 10 + previous] += ways;
            }
        }
        for (int64_t index = 0; index < 100; ++index) current[index] = next[index];
    }

    int64_t total = 0;
    for (int64_t index = 0; index < 100; ++index) total += current[index];
    return total;
}
