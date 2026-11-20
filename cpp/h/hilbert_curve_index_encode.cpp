#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_ORDER = 8;

std::int64_t hilbert_index(std::int64_t order, std::int64_t x,
                           std::int64_t y) noexcept {
    auto current_x = x;
    auto current_y = y;
    std::int64_t distance = 0;
    for (std::int64_t bit_index = order - 1; bit_index >= 0; --bit_index) {
        const auto bit = std::int64_t{1} << bit_index;
        const auto x_bit = (current_x & bit) != 0;
        const auto y_bit = (current_y & bit) != 0;
        distance += bit * bit * ((3 * x_bit) ^ y_bit);

        const auto mask = bit - 1;
        auto low_x = current_x & mask;
        auto low_y = current_y & mask;
        if (!y_bit) {
            if (x_bit) {
                low_x = mask - low_x;
                low_y = mask - low_y;
            }
            current_x = low_y;
            current_y = low_x;
        } else {
            current_x = low_x;
            current_y = low_y;
        }
    }
    return distance;
}

void store_i64_le(std::uint8_t *output, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t hilbert_curve_index_encode(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length != 3) return -1;
    const auto order = input[0];
    if (order < 1 || order > MAX_ORDER) return -1;
    const auto side = std::int64_t{1} << order;
    const auto x = input[1];
    const auto y = input[2];
    if (x < 0 || x >= side || y < 0 || y >= side) return -1;
    if (output == nullptr || capacity < 8) return -2;
    store_i64_le(output, hilbert_index(order, x, y));
    return 8;
}
