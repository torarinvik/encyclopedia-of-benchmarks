/* Count factors of five in n!, which determine its trailing decimal zeros. */
#include <stdint.h>

#define MAX_N 1000000000

int64_t factorial_trailing_zeroes(int64_t n)
{
    if (n < 0 || n > MAX_N) return -1;
    int64_t count = 0;
    while (n > 0) {
        n /= 5;
        count += n;
    }
    return count;
}
