/* Check whether a square can be split into two parts that sum to n. */
#include <stdint.h>

int64_t kaprekar_number(int64_t number)
{
    if (number < 1) return 0;
    if (number > 2000000000LL) return -1;
    if (number == 1) return 1;
    const int64_t square = number * number;
    int64_t split = 10;
    while (split <= square) {
        const int64_t right = square % split;
        if (right > 0 && square / split + right == number) return 1;
        if (split > square / 10) break;
        split *= 10;
    }
    return 0;
}
