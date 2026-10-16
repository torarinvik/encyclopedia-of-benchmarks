// Encode the source divisor list in a lossless positive signed-i64 bit mask.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t divisors(const std::int64_t *values,
                                  std::size_t length) noexcept
{
    if (values == nullptr || length != 1) return -1;
    const std::int64_t n = values[0];
    if (n < 1 || n > 62) return -1;
    std::uint64_t mask = 0;
    for (std::int64_t divisor = 1; divisor <= n; ++divisor) {
        if (n % divisor == 0) mask |= std::uint64_t{1} << divisor;
    }
    return static_cast<std::int64_t>(mask);
}
