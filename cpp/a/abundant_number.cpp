#include <cstdint>

extern "C" std::int64_t abundant_number(std::int64_t n)
{
    if (n < 1 || n > 100'000'000) return -1;
    std::int64_t sum = 1;
    for (std::int64_t divisor = 2; divisor <= n / divisor; ++divisor) {
        if (n % divisor == 0) {
            sum += divisor;
            const std::int64_t partner = n / divisor;
            if (partner != divisor) sum += partner;
            if (sum > n) return 1;
        }
    }
    return 0;
}
