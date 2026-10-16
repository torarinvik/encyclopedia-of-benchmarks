/* Generate Floyd's triangle as flattened little-endian 16-bit values. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxRows = 90;
}

extern "C" std::int64_t floyd_triangle(std::int64_t rows, std::uint8_t *output,
                                         std::size_t output_capacity) noexcept {
    if (rows < 0 || rows > kMaxRows) return -1;
    const auto count = static_cast<std::size_t>(rows) * (static_cast<std::size_t>(rows) + 1) / 2;
    const std::size_t output_length = count * 2;
    if (output_capacity < output_length || (output_length != 0 && output == nullptr)) return -2;

    std::size_t index = 0;
    std::uint32_t number = 1;
    for (std::size_t row = 1; row <= static_cast<std::size_t>(rows); ++row) {
        for (std::size_t column = 0; column < row; ++column) {
            output[index * 2] = static_cast<std::uint8_t>(number & 0xffu);
            output[index * 2 + 1] = static_cast<std::uint8_t>((number >> 8) & 0xffu);
            ++number;
            ++index;
        }
    }
    return static_cast<std::int64_t>(output_length);
}
