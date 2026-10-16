#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_dimension = 16;
constexpr std::size_t max_input_length = 2 + max_dimension * max_dimension;
}

extern "C" std::int64_t nearest_neighbor_interpolation(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_input_length) return -1;
    if (input[0] < 1 || input[0] > max_dimension || input[1] < 1 || input[1] > max_dimension) return -1;
    const auto rows = static_cast<std::size_t>(input[0]);
    const auto columns = static_cast<std::size_t>(input[1]);
    const auto input_cells = rows * columns;
    if (length != 2 + input_cells) return -1;
    for (std::size_t index = 0; index < input_cells; ++index)
        if (input[index + 2] < 0 || input[index + 2] > 255) return -1;

    const auto output_rows = 3 * rows / 2;
    const auto output_columns = 3 * columns / 2;
    const auto output_bytes = output_rows * output_columns;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t y = 0; y < output_rows; ++y) {
        const auto source_y = (4 * (y + 1) + 3) / 6 - 1;
        for (std::size_t x = 0; x < output_columns; ++x) {
            const auto source_x = (4 * (x + 1) + 3) / 6 - 1;
            output[y * output_columns + x] = static_cast<std::uint8_t>(input[2 + source_y * columns + source_x]);
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
