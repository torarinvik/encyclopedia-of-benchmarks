/* Tabulated Fibonacci for the bounded signed 64-bit benchmark contract. */
#include <stdint.h>

int64_t fibonacci_dp(int64_t n)
{
    if (n < 0 || n > 46) {
        return -1;
    }

    int64_t table[47] = {0};
    table[0] = 0;
    table[1] = 1;
    for (int64_t index = 2; index <= n; ++index) {
        table[index] = table[index - 1] + table[index - 2];
    }
    return table[n];
}
