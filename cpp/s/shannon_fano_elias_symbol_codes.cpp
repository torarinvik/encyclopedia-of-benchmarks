#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t shannon_fano_elias_symbol_codes(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 10) return -1;
    const std::int64_t raw_n = input[0];
    if (raw_n < 1 || raw_n > 8 || length != static_cast<std::size_t>(raw_n + 1)) return -1;
    const auto n = static_cast<std::size_t>(raw_n);
    std::int64_t total = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto weight = input[1 + i];
        if (weight < 1 || weight > 15) return -1;
        total += weight;
    }
    if (total > 120) return -1;

    std::array<std::uint8_t, 17> staged{};
    staged[0] = static_cast<std::uint8_t>(n);
    std::int64_t prefix = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto weight = input[1 + i];
        unsigned bits = 1;
        while ((std::int64_t{1} << (bits - 1)) * weight < total) ++bits;
        const auto numerator = (2 * prefix + weight) * (std::int64_t{1} << (bits - 1));
        const auto code = static_cast<std::uint8_t>(numerator / total);
        staged[1 + 2 * i] = static_cast<std::uint8_t>(bits);
        staged[2 + 2 * i] = static_cast<std::uint8_t>(code << (8 - bits));
        prefix += weight;
    }
    const std::size_t needed = 1 + 2 * n;
    if (output == nullptr || capacity < needed) return -2;
    for (std::size_t i = 0; i < needed; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(needed);
}
