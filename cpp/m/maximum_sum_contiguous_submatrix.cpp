#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxParseableInputLength = 67;
constexpr std::size_t kMaxOutputBytes = 8;

void write_i64_le(std::uint8_t *output, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
}
} // namespace

extern "C" std::int64_t maximum_sum_contiguous_submatrix(
        const std::int64_t *input, std::size_t length, std::uint8_t *output,
        std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > kMaxParseableInputLength) return -1;
    const auto rows_value = input[0];
    const auto columns_value = input[1];
    if (rows_value < 1 || rows_value > 8 || columns_value < 1 || columns_value > 8) return -1;
    const auto rows = static_cast<std::size_t>(rows_value);
    const auto columns = static_cast<std::size_t>(columns_value);
    const auto cells = rows * columns;
    if (length != 2 + cells) return -1;
    for (std::size_t index = 0; index < cells; ++index) {
        if (input[index + 2] < -1000 || input[index + 2] > 1000) return -1;
    }

    std::int64_t best = -64001;
    std::array<std::int64_t, 8> column_sums{};
    for (std::size_t top = 0; top < rows; ++top) {
        column_sums.fill(0);
        for (std::size_t bottom = top; bottom < rows; ++bottom) {
            const auto row_offset = 2 + bottom * columns;
            for (std::size_t column = 0; column < columns; ++column) {
                column_sums[column] += input[row_offset + column];
            }
            auto current = column_sums[0];
            if (current > best) best = current;
            for (std::size_t column = 1; column < columns; ++column) {
                current = current < 0 ? column_sums[column] : current + column_sums[column];
                if (current > best) best = current;
            }
        }
    }
    if (output == nullptr || capacity < kMaxOutputBytes) return -2;
    write_i64_le(output, best);
    return static_cast<std::int64_t>(kMaxOutputBytes);
}
