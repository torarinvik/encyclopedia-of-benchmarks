/* Sum LCM(i, n), 1 <= i <= n, using the Euler-totient identity. */
#include <cstdint>

static std::uint64_t euler_phi(std::uint64_t value)
{
    auto result = value;
    auto remaining = value;
    for (std::uint64_t factor = 2; factor <= remaining / factor;
         factor += factor == 2 ? 1 : 2) {
        if (remaining % factor == 0) {
            result -= result / factor;
            do { remaining /= factor; } while (remaining % factor == 0);
        }
    }
    if (remaining > 1) result -= result / remaining;
    return result;
}

extern "C" std::int64_t lcm_sum(std::int64_t input) noexcept
{
    if (input < 1 || input > 65535) return -1;
    const auto n = static_cast<std::uint64_t>(input);
    std::uint64_t weighted_totients = 1;
    for (std::uint64_t divisor = 1; divisor <= n / divisor; ++divisor) {
        if (n % divisor == 0) {
            weighted_totients += divisor * euler_phi(divisor);
            const auto paired = n / divisor;
            if (paired != divisor) weighted_totients += paired * euler_phi(paired);
        }
    }
    return static_cast<std::int64_t>((weighted_totients * n) / 2);
}
