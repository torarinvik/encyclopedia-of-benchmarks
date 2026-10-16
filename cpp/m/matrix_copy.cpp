#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_dimension = 32;
constexpr std::size_t max_input_length = 2 + max_dimension * max_dimension;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t matrix_copy(const std::int64_t *values, std::size_t length,
                                    std::uint8_t *output, std::size_t output_capacity) {
    if (values == nullptr || length < 2 || length > max_input_length) return -1;
    const std::int64_t rows_value = values[0], columns_value = values[1];
    if (rows_value < 0 || rows_value > static_cast<std::int64_t>(max_dimension) ||
        columns_value < 0 || columns_value > static_cast<std::int64_t>(max_dimension)) return -1;
    const std::size_t rows = static_cast<std::size_t>(rows_value);
    const std::size_t columns = static_cast<std::size_t>(columns_value);
    const std::size_t element_count = rows * columns;
    if (length != 2 + element_count) return -1;
    for (std::size_t index = 0; index < element_count; ++index)
        if (values[2 + index] < std::numeric_limits<std::int32_t>::min() ||
            values[2 + index] > std::numeric_limits<std::int32_t>::max()) return -1;
    const std::size_t result_rows = rows == 0 || columns == 0 ? 0 : rows;
    const std::size_t result_columns = rows == 0 || columns == 0 ? 0 : columns;
    const std::size_t result_count = result_rows * result_columns;
    const std::size_t output_bytes = (2 + result_count) * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    store_i64_le(output, 0, static_cast<std::int64_t>(result_rows));
    store_i64_le(output, 8, static_cast<std::int64_t>(result_columns));
    for (std::size_t index = 0; index < result_count; ++index)
        store_i64_le(output, 16 + index * 8, values[2 + index]);
    return static_cast<std::int64_t>(output_bytes);
}
