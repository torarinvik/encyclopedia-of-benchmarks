#include <stdint.h>

int64_t abundant_number(int64_t n)
{
    if (n < 1 || n > 1000000000) return -1;
    int64_t sum = 1;
    for (int64_t divisor = 2; divisor <= n / divisor; ++divisor) {
        if (n % divisor == 0) {
            sum += divisor;
            const int64_t partner = n / divisor;
            if (partner != divisor) sum += partner;
            if (sum > n) return 1;
        }
    }
    return 0;
}
