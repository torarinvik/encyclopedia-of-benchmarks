/* Return the exact Bell number for indices that fit in signed 64-bit output. */
#include <stdint.h>

int64_t bell_numbers(int64_t n)
{
    if (n < 0 || n > 25) return -1;
    if (n == 0) return 1;

    int64_t row[26] = {0};
    row[0] = 1;
    for (int64_t current = 1; current < n; ++current) {
        const int64_t previous_first = row[0];
        const int64_t previous_last = row[current - 1];
        row[0] = previous_last;
        int64_t previous_old = previous_first;
        for (int64_t column = 1; column <= current; ++column) {
            const int64_t old_value = column < current ? row[column] : 0;
            row[column] = row[column - 1] + previous_old;
            previous_old = old_value;
        }
    }
    return row[n - 1];
}
