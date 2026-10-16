#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = INT64_MIN;
constexpr std::size_t max_dimension = 16;

void put_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) noexcept {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t dilation_operation(const std::int64_t* input, std::size_t length,
                                            std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 12 || length > 2 + max_dimension * max_dimension + 9) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_dimension) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_dimension)) return -1;
    const auto rows = static_cast<std::size_t>(input[0]);
    const auto columns = static_cast<std::size_t>(input[1]);
    const auto cells = rows * columns;
    if (length != 2 + cells + 9) return -1;
    for (std::size_t i = 0; i < cells + 9; ++i) if (input[2 + i] < 0 || input[2 + i] > 1) return -1;
    if (output == nullptr || output_capacity < cells * 4) return -2;
    for (std::size_t y = 0; y < rows; ++y) for (std::size_t x = 0; x < columns; ++x) {
        std::int32_t sum = 0;
        for (std::size_t ky = 0; ky < 3; ++ky) for (std::size_t kx = 0; kx < 3; ++kx) {
            const auto image_y = static_cast<std::int64_t>(y) + static_cast<std::int64_t>(ky) - 1;
            const auto image_x = static_cast<std::int64_t>(x) + static_cast<std::int64_t>(kx) - 1;
            if (image_y >= 0 && image_y < static_cast<std::int64_t>(rows) && image_x >= 0 &&
                image_x < static_cast<std::int64_t>(columns)) {
                sum += static_cast<std::int32_t>(
                    input[2 + static_cast<std::size_t>(image_y) * columns + static_cast<std::size_t>(image_x)] *
                    input[2 + cells + ky * 3 + kx]);
            }
        }
        put_i32_le(output, (y * columns + x) * 4, sum > 0 ? 1 : 0);
    }
    return static_cast<std::int64_t>(cells);
}
