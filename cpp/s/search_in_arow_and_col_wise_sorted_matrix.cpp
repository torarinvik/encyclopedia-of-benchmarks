#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 63;
constexpr std::size_t max_input_values = 2 + max_dimension * max_dimension;
constexpr std::int64_t int32_minimum = -2'147'483'648LL;
constexpr std::int64_t int32_maximum = 2'147'483'647LL;

void write_i32_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(value));
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t search_in_arow_and_col_wise_sorted_matrix(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input_values) return -1;
    const auto n_value = input[0];
    const auto target = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_dimension) ||
        target < int32_minimum || target > int32_maximum) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != 2 + n * n) return -1;

    std::size_t target_count = 0;
    for (std::size_t row = 0; row < n; ++row) {
        for (std::size_t column = 0; column < n; ++column) {
            const auto index = row * n + column;
            const auto value = input[2 + index];
            if (value < int32_minimum || value > int32_maximum) return -1;
            if (column > 0 && value < input[2 + index - 1]) return -1;
            if (row > 0 && value < input[2 + index - n]) return -1;
            if (value == target && ++target_count > 1) return -1;
        }
    }

    std::size_t row = 0;
    auto column = static_cast<std::int64_t>(n) - 1;
    std::int64_t result_row = -1, result_column = -1, found = 0;
    while (row < n && column >= 0) {
        const auto value = input[2 + row * n + static_cast<std::size_t>(column)];
        if (value == target) {
            result_row = static_cast<std::int64_t>(row);
            result_column = column;
            found = 1;
            break;
        }
        if (target > value) ++row;
        else --column;
    }

    if (output == nullptr || capacity < 8) return -2;
    std::uint8_t buffer[8]{};
    write_i32_le(buffer, 0, result_row);
    write_i32_le(buffer, 4, result_column);
    for (std::size_t index = 0; index < 8; ++index) output[index] = buffer[index];
    return found;
}
