#include <cstddef>
#include <cstdint>

namespace {
void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>((bits >> (8 * byte)) & 0xffu);
    }
}
}

extern "C" std::int64_t cross_correlation(const std::int64_t* values, std::size_t length,
                                          std::uint8_t* output, std::size_t capacity) noexcept {
    if (values == nullptr || length < 4 || length > 66) return -1;
    const std::int64_t raw_x_count = values[0];
    const std::int64_t raw_y_count = values[1];
    if (raw_x_count < 1 || raw_x_count > 32 || raw_y_count < 1 || raw_y_count > 32) return -1;
    const std::size_t x_count = static_cast<std::size_t>(raw_x_count);
    const std::size_t y_count = static_cast<std::size_t>(raw_y_count);
    if (length != x_count + y_count + 2) return -1;
    for (std::size_t i = 0; i < x_count + y_count; ++i) {
        if (values[i + 2] < -1000000 || values[i + 2] > 1000000) return -1;
    }
    const std::size_t result_count = x_count + y_count - 1;
    const std::size_t byte_count = 8 * result_count;
    if (output == nullptr || capacity < byte_count) return -2;

    std::size_t y_start = y_count;
    for (std::size_t index = 0; index < result_count; ++index) {
        if (index < y_count) --y_start;
        const std::size_t k_min = index >= y_count - 1 ? index - (y_count - 1) : 0;
        const std::size_t k_max = index < x_count ? index : x_count - 1;
        std::int64_t sum = 0;
        for (std::size_t k = k_min; k <= k_max; ++k) {
            const std::size_t y_index = y_start + (k - k_min);
            sum += values[k + 2] * values[x_count + y_index + 2];
        }
        store_i64_le(output, index * 8, sum);
    }
    return static_cast<std::int64_t>(byte_count);
}
