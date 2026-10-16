// Emit the sorted unique pairwise sums of two bounded integer sets.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t min_sum = -2000;
constexpr std::int64_t max_sum = 2000;
constexpr std::size_t sum_count = 4001;
constexpr std::int64_t max_set_size = 64;

std::size_t decimal_width(std::int64_t value) {
    std::size_t width = 1;
    if (value < 0) { value = -value; ++width; }
    while (value >= 10) { value /= 10; ++width; }
    return width;
}

std::size_t append_signed_decimal(std::uint8_t *output, std::size_t position, std::int64_t value) {
    if (value < 0) { output[position++] = '-'; value = -value; }
    std::uint8_t digits[20];
    std::size_t count = 0;
    do { digits[count++] = static_cast<std::uint8_t>(value % 10); value /= 10; } while (value != 0);
    while (count > 0) output[position++] = static_cast<std::uint8_t>('0' + digits[--count]);
    return position;
}
}

extern "C" std::int64_t sumset(const std::int64_t *values, std::size_t length,
                                std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 2) return -1;
    const std::int64_t count_a = values[0], count_b = values[1];
    if (count_a < 0 || count_a > max_set_size || count_b < 0 || count_b > max_set_size ||
        length != 2 + static_cast<std::size_t>(count_a) + static_cast<std::size_t>(count_b)) return -1;
    bool present[sum_count] = {};
    for (std::size_t index_a = 0; index_a < static_cast<std::size_t>(count_a); ++index_a)
        if (values[2 + index_a] < -1000 || values[2 + index_a] > 1000) return -1;
    for (std::size_t index_b = 0; index_b < static_cast<std::size_t>(count_b); ++index_b) {
        const std::int64_t right = values[2 + static_cast<std::size_t>(count_a) + index_b];
        if (right < -1000 || right > 1000) return -1;
    }
    for (std::size_t index_a = 0; index_a < static_cast<std::size_t>(count_a); ++index_a) {
        const std::int64_t left = values[2 + index_a];
        for (std::size_t index_b = 0; index_b < static_cast<std::size_t>(count_b); ++index_b) {
            const std::int64_t right = values[2 + static_cast<std::size_t>(count_a) + index_b];
            present[left + right - min_sum] = true;
        }
    }
    std::size_t needed = 0;
    for (std::int64_t sum = min_sum; sum <= max_sum; ++sum)
        if (present[sum - min_sum]) needed += decimal_width(sum) + 1;
    if (needed == 0) return 0;
    if (output == nullptr || output_capacity < needed) return -2;
    std::size_t position = 0;
    for (std::int64_t sum = min_sum; sum <= max_sum; ++sum) {
        if (!present[sum - min_sum]) continue;
        position = append_signed_decimal(output, position, sum);
        output[position++] = '\n';
    }
    return static_cast<std::int64_t>(position);
}
