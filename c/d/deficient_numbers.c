/* Proper-divisor pair scan from the pinned Python source. */
#include <stdint.h>

int64_t deficient_numbers(int64_t number)
{
    if (number <= 0) return 0;
    if (number > 100000000) return -1;
    if (number == 1) return 1;

    int64_t sum = 1;
    for (int64_t divisor = 2; divisor <= number / divisor; ++divisor) {
        if (number % divisor == 0) {
            const int64_t other = number / divisor;
            sum += divisor;
            if (other != divisor) sum += other;
        }
    }
    return sum < number ? 1 : 0;
}
