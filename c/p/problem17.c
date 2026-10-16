#include <stdint.h>

int64_t problem17(int64_t limit)
{
    if (limit < 0 || limit > 1000) return -1;
    static const int64_t ones[20] = {0, 3, 3, 5, 4, 4, 3, 5, 5, 4, 3, 6, 6, 8, 8, 7, 7, 9, 8, 8};
    static const int64_t tens[10] = {0, 0, 6, 6, 5, 5, 5, 7, 6, 6};
    int64_t total = 0;
    for (int64_t value = 1; value <= limit; ++value) {
        if (value == 1000) {
            total += ones[1] + 8;
            continue;
        }
        int64_t remainder = value;
        if (value >= 100) {
            total += ones[value / 100] + 7;
            remainder = value % 100;
            if (remainder != 0) total += 3;
        }
        if (remainder < 20) total += ones[remainder];
        else total += tens[remainder / 10] + ones[remainder % 10];
    }
    return total;
}
