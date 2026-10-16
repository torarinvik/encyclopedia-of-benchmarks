#include <cstddef>
#include <cstdint>

namespace {
void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t convolution(const std::int64_t* values, std::size_t length,
                                     std::uint8_t* output, std::size_t capacity) noexcept {
    if (values == nullptr || length < 4 || length > 130) return -1;
    const auto raw_a_count = values[0];
    const auto raw_b_count = values[1];
    if (raw_a_count < 1 || raw_a_count > 64 || raw_b_count < 1 || raw_b_count > 64) return -1;
    const auto a_count = static_cast<std::size_t>(raw_a_count);
    const auto b_count = static_cast<std::size_t>(raw_b_count);
    if (length != a_count + b_count + 2) return -1;
    for (std::size_t i = 0; i < a_count + b_count; ++i) {
        if (values[i + 2] < -1000000 || values[i + 2] > 1000000) return -1;
    }
    const auto result_count = a_count + b_count - 1;
    const auto byte_count = result_count * 8;
    if (output == nullptr || capacity < byte_count) return -2;
    for (std::size_t i = 0; i < result_count; ++i) {
        const auto k_start = i >= b_count - 1 ? i - (b_count - 1) : 0;
        const auto k_end = i < a_count ? i : a_count - 1;
        std::int64_t sum = 0;
        for (std::size_t k = k_start; k <= k_end; ++k) sum += values[k + 2] * values[a_count + (i - k) + 2];
        store_i64_le(output, i * 8, sum);
    }
    return static_cast<std::int64_t>(byte_count);
}
