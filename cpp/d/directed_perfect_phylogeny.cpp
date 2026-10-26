#include <cstddef>
#include <cstdint>

extern "C" std::int64_t directed_perfect_phylogeny(const std::int64_t *input, std::size_t length,
                                                   std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 3 || length > 146) return -1;
    const auto n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > 12 || m0 < 1 || m0 > 12 || length != 2 + static_cast<std::size_t>(n0 * m0)) return -1;
    const auto n = static_cast<std::size_t>(n0), m = static_cast<std::size_t>(m0);
    std::uint16_t sets[12]{};
    for (std::size_t row = 0; row < n; ++row) for (std::size_t col = 0; col < m; ++col) {
        const auto bit = input[2 + row * m + col];
        if (bit != 0 && bit != 1) return -1;
        if (bit) sets[col] |= static_cast<std::uint16_t>(1u << row);
    }
    std::int64_t feasible = 1;
    for (std::size_t a = 0; a < m; ++a) for (std::size_t b = a + 1; b < m; ++b) {
        const auto overlap = static_cast<std::uint16_t>(sets[a] & sets[b]);
        if (overlap != 0 && overlap != sets[a] && overlap != sets[b]) feasible = 0;
    }
    if (!output || capacity < 8) return -2;
    const auto bits = static_cast<std::uint64_t>(feasible);
    for (std::size_t b = 0; b < 8; ++b) output[b] = static_cast<std::uint8_t>(bits >> (8 * b));
    return 8;
}
