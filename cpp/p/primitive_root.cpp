/* Search in ascending order for a full period of distinct residues. */
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t primitive_root(const std::int64_t *input,
                                        std::size_t length) noexcept
{
    if (input == nullptr || length != 1 || input[0] < 2 || input[0] > 127) return -1;
    const auto modulus = input[0];
    for (std::int64_t candidate = 1; candidate < modulus; ++candidate) {
        std::array<bool, 127> seen{};
        auto power = std::int64_t{1};
        bool distinct = true;
        for (std::int64_t exponent = 0; exponent < modulus - 1; ++exponent) {
            if (seen[static_cast<std::size_t>(power)]) { distinct = false; break; }
            seen[static_cast<std::size_t>(power)] = true;
            power = (power * candidate) % modulus;
        }
        if (distinct) return candidate;
    }
    return 0;
}
