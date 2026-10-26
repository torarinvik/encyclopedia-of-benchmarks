#include <cstddef>
#include <cstdint>

namespace {
void put_i64(std::uint8_t *out, std::size_t at, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[at * 8 + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t approximate_tandem_squares(const std::int64_t *input, std::size_t length,
                                                    std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 2 || length > 34) return -1;
    const auto n0 = input[0], budget = input[1];
    if (n0 < 2 || n0 > 32 || budget < 0 || budget > 8 || length != static_cast<std::size_t>(n0) + 2) return -1;
    const auto n = static_cast<std::size_t>(n0);
    for (std::size_t i = 0; i < n; ++i) if (input[2 + i] < 0 || input[2 + i] > 3) return -1;
    std::int64_t records[256][3]{};
    std::size_t count = 0;
    for (std::size_t start = 0; start < n; ++start) {
        for (std::size_t period = 1; 2 * period <= n - start; ++period) {
            std::int64_t mismatches = 0;
            for (std::size_t i = 0; i < period; ++i)
                mismatches += input[2 + start + i] != input[2 + start + period + i];
            if (mismatches <= budget) {
                records[count][0] = static_cast<std::int64_t>(start);
                records[count][1] = static_cast<std::int64_t>(period);
                records[count][2] = mismatches;
                ++count;
            }
        }
    }
    const auto bytes = 8 * (1 + 3 * count);
    if (!output || capacity < bytes) return -2;
    put_i64(output, 0, static_cast<std::int64_t>(count));
    for (std::size_t i = 0; i < count; ++i)
        for (std::size_t j = 0; j < 3; ++j) put_i64(output, 1 + 3 * i + j, records[i][j]);
    return static_cast<std::int64_t>(bytes);
}
