// Proper-divisor pair scan from the pinned Python source.
#include <cstdint>

extern "C" std::int64_t deficient_numbers(std::int64_t number) noexcept
{
    if (number <= 0) return 0;
    if (number > 100'000'000) return -1;
    if (number == 1) return 1;

    std::int64_t sum = 1;
    for (std::int64_t divisor = 2; divisor <= number / divisor; ++divisor) {
        if (number % divisor == 0) {
            const auto other = number / divisor;
            sum += divisor;
            if (other != divisor) sum += other;
        }
    }
    return sum < number ? 1 : 0;
}
