#include <cstddef>
#include <cstdint>

namespace {
void put_i64(std::uint8_t *out, std::size_t at, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[at * 8 + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t first_fit_cardinality_bin_packing(const std::int64_t *input, std::size_t length,
                                                           std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 4 || length > 35) return -1;
    const auto n0 = input[0], limit = input[1], cap = input[2];
    if (n0 < 1 || n0 > 32 || limit < 1 || limit > 32 || cap < 1 || cap > 10000 || length != static_cast<std::size_t>(n0) + 3) return -1;
    const auto n = static_cast<std::size_t>(n0);
    for (std::size_t i = 0; i < n; ++i) if (input[3 + i] < 1 || input[3 + i] > cap) return -1;
    std::int64_t loads[32]{}, used[32]{}, assignment[32]{};
    std::size_t bins = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto size = input[3 + i]; std::size_t b = 0;
        while (b < bins && (used[b] >= limit || loads[b] > cap - size)) ++b;
        if (b == bins) ++bins;
        loads[b] += size; ++used[b]; assignment[i] = static_cast<std::int64_t>(b);
    }
    const auto bytes = 8 * (n + 1);
    if (!output || capacity < bytes) return -2;
    put_i64(output, 0, static_cast<std::int64_t>(bins));
    for (std::size_t i = 0; i < n; ++i) put_i64(output, i + 1, assignment[i]);
    return static_cast<std::int64_t>(bytes);
}
