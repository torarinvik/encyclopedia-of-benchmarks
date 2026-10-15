#include <cstdint>

static std::int64_t sum_divisors(std::uint64_t number)
{
    std::int64_t sum = 0;
    for (std::uint64_t divisor = 1; divisor * divisor <= number; ++divisor) {
        if (number % divisor == 0) {
            sum += static_cast<std::int64_t>(divisor);
            const auto other = number / divisor;
            if (other != divisor) sum += static_cast<std::int64_t>(other);
        }
    }
    return sum;
}

extern "C" std::int64_t friendly_number(std::uint64_t a, std::uint64_t b) noexcept
{
    if (a > 1000000 || b > 1000000) return -1;
    if (a == 0 || b == 0) return 0;
    const auto sigma_a = sum_divisors(a), sigma_b = sum_divisors(b);
    return sigma_a * static_cast<std::int64_t>(b) == sigma_b * static_cast<std::int64_t>(a) ? 1 : 0;
}
