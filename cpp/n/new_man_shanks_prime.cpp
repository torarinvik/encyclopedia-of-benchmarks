#include <cstdint>

namespace {
constexpr std::int64_t MAX_INDEX = 25;
constexpr std::int64_t INT32_MIN_VALUE = -2147483648LL;
constexpr std::int64_t INT32_MAX_VALUE = 2147483647LL;
}

// Compare the source recurrence term a[n] with expected; no primality test.
extern "C" std::int64_t new_man_shanks_prime(std::int64_t n, std::int64_t expected) noexcept
{
    if (n < 1 || n > MAX_INDEX || expected < INT32_MIN_VALUE || expected > INT32_MAX_VALUE) return -1;
    std::int32_t previous_previous = 1;
    std::int32_t previous = 1;
    if (n == 1) return expected == previous ? 1 : 0;
    for (std::int64_t index = 2; index <= n; ++index) {
        const std::int32_t current = 2 * previous + previous_previous;
        previous_previous = previous;
        previous = current;
    }
    return previous == expected ? 1 : 0;
}
