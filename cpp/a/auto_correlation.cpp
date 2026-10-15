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

extern "C" std::int64_t auto_correlation(const std::int64_t* values, std::size_t length,
                                            std::uint8_t* output, std::size_t capacity) {
    if (values == nullptr || length < 2 || length > 65) return -1;
    const std::int64_t raw_count = values[0];
    if (raw_count < 1 || raw_count > 64) return -1;
    const std::size_t count = static_cast<std::size_t>(raw_count);
    if (length != count + 1) return -1;
    for (std::size_t i = 0; i < count; ++i) {
        if (values[i + 1] < -1000000 || values[i + 1] > 1000000) return -1;
    }
    const std::size_t result_count = 2 * count - 1;
    const std::size_t byte_count = 8 * result_count;
    if (output == nullptr || capacity < byte_count) return -2;

    std::size_t y_start = count;
    for (std::size_t index = 0; index < result_count; ++index) {
        if (index < count) --y_start;
        const std::size_t k_min = index >= count - 1 ? index - (count - 1) : 0;
        const std::size_t k_max = index < count ? index : count - 1;
        std::size_t offset = 0;
        std::int64_t sum = 0;
        for (std::size_t k = k_min; k <= k_max; ++k) {
            sum += values[k + 1] * values[y_start + offset + 1];
            ++offset;
        }
        store_i64_le(output, index * 8, sum);
    }
    return static_cast<std::int64_t>(byte_count);
}
