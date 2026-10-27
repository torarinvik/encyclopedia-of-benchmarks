#include <cstddef>
#include <cstdint>

namespace {
void put_i64(std::uint8_t *out, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[word * 8 + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t next_fit_bin_packing(const std::int64_t *input, std::size_t length,
                                               std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 65) return -1;
    const auto n0 = input[0];
    if (n0 < 0 || n0 > 64 || length != 1 + static_cast<std::size_t>(n0)) return -1;
    const auto n = static_cast<std::size_t>(n0);
    for (std::size_t i = 0; i < n; ++i) if (input[i + 1] < 1 || input[i + 1] > 1000000) return -1;
    std::int64_t assignments[64] = {};
    std::int64_t bins = 0, remaining = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto size = input[i + 1];
        if (bins == 0 || size > remaining) { assignments[i] = bins++; remaining = 1000000 - size; }
        else { assignments[i] = bins - 1; remaining -= size; }
    }
    const auto bytes = 8 * (n + 1);
    if (output == nullptr || capacity < bytes) return -2;
    put_i64(output, 0, bins);
    for (std::size_t i = 0; i < n; ++i) put_i64(output, i + 1, assignments[i]);
    return static_cast<std::int64_t>(bytes);
}
