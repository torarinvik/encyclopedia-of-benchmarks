/* Check whether n equals the sum of factorials of its decimal digits. */
#include <stdint.h>

int64_t krishnamurthy_number_checker(int64_t n)
{
    if (n < INT32_MIN || n > INT32_MAX) return -1;
    if (n <= 0) return 0;

    static const int32_t factorials[10] = {1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880};
    const int64_t original = n;
    int64_t sum = 0;
    while (n != 0) {
        sum += factorials[n % 10];
        n /= 10;
    }
    return sum == original ? 1 : 0;
}
