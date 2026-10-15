#include <cstddef>
#include <cstdint>

namespace {
void store_i64_le(std::int64_t value, std::uint8_t *output, std::size_t offset) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t matrix_multiplication(const std::int64_t *input, std::size_t length,
                                               std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 1) return -2;
    const auto dimension = input[0];
    if (dimension < 2 || dimension > 8) return -2;
    const auto n = static_cast<std::size_t>(dimension);
    const auto cells = n * n;
    if (length != 1 + 2 * cells) return -2;
    for (std::size_t index = 0; index < 2 * cells; ++index) {
        if (input[1 + index] < -1000 || input[1 + index] > 1000) return -2;
    }
    if (output == nullptr || output_capacity < cells * 8) return -3;

    for (std::size_t row = 0; row < n; ++row) {
        for (std::size_t column = 0; column < n; ++column) {
            std::int64_t sum = 0;
            for (std::size_t index = 0; index < n; ++index) {
                sum += input[1 + row * n + index] * input[1 + cells + index * n + column];
            }
            store_i64_le(sum, output, (row * n + column) * 8);
        }
    }
    return static_cast<std::int64_t>(cells);
}
