#include <cstdint>
#include <vector>

extern "C" std::int64_t problem72(std::int64_t limit) noexcept
{
    if (limit < 0 || limit > 1'000'000) return -1;
    if (limit < 2) return 0;
    std::vector<std::uint32_t> phi(static_cast<std::size_t>(limit) + 1);
    if (limit >= 1) phi[1] = 1;
    for (std::int64_t value = 2; value <= limit; ++value) phi[value] = static_cast<std::uint32_t>(value);
    for (std::int64_t prime = 2; prime <= limit; ++prime) {
        if (phi[prime] == static_cast<std::uint32_t>(prime)) {
            for (std::int64_t multiple = prime; multiple <= limit; multiple += prime)
                phi[multiple] -= phi[multiple] / static_cast<std::uint32_t>(prime);
        }
    }
    std::int64_t total = 0;
    for (std::int64_t denominator = 2; denominator <= limit; ++denominator) total += phi[denominator];
    return total;
}
