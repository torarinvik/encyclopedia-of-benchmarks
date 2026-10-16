/* Find the first partition number divisible by the requested modulus. */
#include <cstdint>

namespace {
constexpr std::int64_t MAX_MODULUS = 1000000;
constexpr std::int64_t MAX_INDEX = 55374;

std::int64_t positive_mod(std::int64_t value, std::int64_t modulus)
{
    value %= modulus;
    return value < 0 ? value + modulus : value;
}
}

extern "C" std::int64_t problem78(std::int64_t modulus) noexcept
{
    if (modulus < 1 || modulus > MAX_MODULUS) return -1;
    std::uint32_t partitions[MAX_INDEX + 1] = {1};
    for (std::int64_t n = 1; n <= MAX_INDEX; ++n) {
        std::int64_t value = 0;
        for (std::int64_t j = 1;; ++j) {
            const std::int64_t first = (3 * j * j - j) / 2;
            if (first > n) break;
            const std::int64_t sign = j % 2 == 0 ? -1 : 1;
            value = positive_mod(value + sign * partitions[n - first], modulus);
            const std::int64_t second = first + j;
            if (second > n) break;
            value = positive_mod(value + sign * partitions[n - second], modulus);
        }
        if (value == 0) return n;
        partitions[n] = static_cast<std::uint32_t>(value);
    }
    return -1;
}
