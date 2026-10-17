#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_parseable_input_length = 259;
constexpr std::int64_t min_i32 = -2147483648LL;
constexpr std::int64_t max_i32 = 2147483647LL;

void store_i32_le(std::uint8_t *output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
} // namespace

extern "C" std::int64_t mirror_of_matrix(const std::int64_t *values,
                                          std::size_t length,
                                          std::uint8_t *output,
                                          std::size_t capacity) {
    if (values == nullptr || length < 2 || length > max_parseable_input_length) return -1;
    const auto raw_rows = values[0], raw_columns = values[1];
    if (raw_rows < 1 || raw_rows > 16 || raw_columns < 1 || raw_columns > 16) return -1;
    const auto rows = static_cast<std::size_t>(raw_rows);
    const auto columns = static_cast<std::size_t>(raw_columns);
    const auto cell_count = rows * columns;
    if (length != 2 + cell_count) return -1;
    for (std::size_t index = 0; index < cell_count; ++index)
        if (values[2 + index] < min_i32 || values[2 + index] > max_i32) return -1;

    const auto byte_count = 4 * cell_count;
    if (output == nullptr || capacity < byte_count) return -2;
    for (std::size_t row = 0; row < rows; ++row)
        for (std::size_t column = 0; column < columns; ++column)
            store_i32_le(output, 4 * (row * columns + column), static_cast<std::int32_t>(
                values[2 + row * columns + (columns - 1 - column)]));
    return static_cast<std::int64_t>(byte_count);
}
