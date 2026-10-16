#include <cstddef>
#include <cstdint>

namespace {
void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t difference_array(const std::int64_t* input, std::size_t length,
                                           std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2) return -1;
    const auto raw_n = input[0], raw_q = input[1];
    if (raw_n < 1 || raw_n > 64 || raw_q < 0 || raw_q > 64) return -1;
    const auto n = static_cast<std::size_t>(raw_n), q = static_cast<std::size_t>(raw_q);
    if (length != 2 + n + 3 * q) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[2 + i] < -1000000 || input[2 + i] > 1000000) return -1;
    for (std::size_t u = 0; u < q; ++u) {
        const auto base = 2 + n + 3 * u;
        if (input[base] < 0 || input[base] >= raw_n || input[base + 1] < input[base] || input[base + 1] >= raw_n ||
            input[base + 2] < -1000000 || input[base + 2] > 1000000) return -1;
    }
    const auto bytes = n * 8;
    if (output == nullptr || capacity < bytes) return -2;
    std::int64_t diff[65] = {};
    diff[0] = input[2];
    for (std::size_t i = 1; i < n; ++i) diff[i] = input[2 + i] - input[2 + i - 1];
    for (std::size_t u = 0; u < q; ++u) {
        const auto base = 2 + n + 3 * u;
        const auto left = static_cast<std::size_t>(input[base]);
        const auto right = static_cast<std::size_t>(input[base + 1]);
        const auto delta = input[base + 2];
        diff[left] += delta;
        diff[right + 1] -= delta;
    }
    auto current = diff[0];
    put_i64_le(output, 0, current);
    for (std::size_t i = 1; i < n; ++i) { current += diff[i]; put_i64_le(output, i * 8, current); }
    return static_cast<std::int64_t>(bytes);
}
