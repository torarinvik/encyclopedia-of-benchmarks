/* Compute one finite, non-wrapping Conway Game of Life generation. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxSide = 32;
}

extern "C" std::int64_t game_of_life(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output,
                                      std::size_t output_capacity) noexcept {
    if (input == nullptr || length == 0) return -1;
    const auto side_value = input[0];
    if (side_value < 0 || side_value > kMaxSide) return -1;
    const auto side = static_cast<std::size_t>(side_value);
    const std::size_t cell_count = side * side;
    if (length != cell_count + 1) return -1;
    for (std::size_t index = 0; index < cell_count; ++index) {
        if (input[index + 1] != 0 && input[index + 1] != 1) return -1;
    }
    if (output_capacity < cell_count || (cell_count != 0 && output == nullptr)) return -2;

    for (std::size_t row = 0; row < side; ++row) {
        for (std::size_t column = 0; column < side; ++column) {
            unsigned neighbors = 0;
            for (int row_delta = -1; row_delta <= 1; ++row_delta) {
                for (int column_delta = -1; column_delta <= 1; ++column_delta) {
                    if (row_delta == 0 && column_delta == 0) continue;
                    const auto neighbor_row = static_cast<std::int64_t>(row) + row_delta;
                    const auto neighbor_column = static_cast<std::int64_t>(column) + column_delta;
                    if (neighbor_row >= 0 && neighbor_row < side_value &&
                        neighbor_column >= 0 && neighbor_column < side_value &&
                        input[1 + static_cast<std::size_t>(neighbor_row) * side +
                              static_cast<std::size_t>(neighbor_column)] == 1) {
                        ++neighbors;
                    }
                }
            }
            const std::size_t index = row * side + column;
            const bool alive = input[index + 1] == 1;
            output[index] = static_cast<std::uint8_t>(alive ? (neighbors == 2 || neighbors == 3)
                                                            : (neighbors == 3));
        }
    }
    return static_cast<std::int64_t>(cell_count);
}
