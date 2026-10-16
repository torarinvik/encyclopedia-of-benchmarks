#include <cstddef>
#include <cstdint>

namespace {
void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
}

bool is_filled(std::size_t row, std::size_t col) {
    while (row != 0 || col != 0) {
        if (row % 3 == 1 && col % 3 == 1) return false;
        row /= 3;
        col /= 3;
    }
    return true;
}
}

extern "C" std::int64_t sierpinski_carpet(const std::int64_t *input, std::size_t length,
                                           std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 3) return -1;
    const auto depth = input[0], filled = input[1], hole = input[2];
    if (depth < 0 || depth > 4 || filled < 32 || filled > 126 ||
        hole < 32 || hole > 126 || filled == hole) return -1;
    std::size_t side = 1;
    for (std::int64_t i = 0; i < depth; ++i) side *= 3;
    const std::size_t needed = 8 + side * side + side - 1;
    if (output == nullptr || capacity < needed) return -2;

    write_i64_le(output, 0, static_cast<std::int64_t>(side));
    std::size_t out = 8;
    for (std::size_t row = 0; row < side; ++row) {
        for (std::size_t col = 0; col < side; ++col) {
            output[out++] = static_cast<std::uint8_t>(is_filled(row, col) ? filled : hole);
        }
        if (row + 1 < side) output[out++] = static_cast<std::uint8_t>('\n');
    }
    return static_cast<std::int64_t>(needed);
}
