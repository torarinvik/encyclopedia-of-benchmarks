/* Check the Fibonacci square identity without overflowing signed 64-bit values. */
#include <stdint.h>

static int square_i64(int64_t value)
{
    if (value < 0) return 0;
    int64_t low = 0;
    int64_t high = 3037000499;
    while (low <= high) {
        const int64_t middle = low + (high - low) / 2;
        const int64_t square = middle * middle;
        if (square == value) return 1;
        if (square < value) low = middle + 1;
        else high = middle - 1;
    }
    return 0;
}

int64_t fibonacci_number_check(int64_t number)
{
    if (number < -1300000000LL || number > 1300000000LL) return -1;
    const int64_t value = 5 * number * number;
    return square_i64(value + 4) || square_i64(value - 4) ? 1 : 0;
}
