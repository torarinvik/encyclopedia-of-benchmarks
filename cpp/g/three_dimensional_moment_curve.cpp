#include <cstddef>
#include <cstdint>

namespace {
void put_i64(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { out[offset + byte] = static_cast<std::uint8_t>(bits & 255); bits >>= 8; }
}
}

extern "C" std::int64_t three_dimensional_moment_curve(const std::int64_t *values, std::size_t length,
                                                        std::uint8_t *output, std::size_t capacity) {
    if (values == nullptr || length != 1 || values[0] < 0 || values[0] > 64) return -1;
    const auto n = static_cast<std::size_t>(values[0]); const auto bytes = 8 * (1 + 3 * n);
    if (output == nullptr || capacity < bytes) return -2;
    std::uint8_t staged[1544]{}; put_i64(staged, 0, static_cast<std::int64_t>(n));
    for (std::size_t i = 1; i <= n; ++i) {
        const auto x = static_cast<std::int64_t>(i), offset = 8 * (1 + 3 * (i - 1));
        put_i64(staged, offset, x); put_i64(staged, offset + 8, x * x); put_i64(staged, offset + 16, x * x * x);
    }
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(bytes);
}
