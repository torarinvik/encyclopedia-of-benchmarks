#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_rows = 16;
constexpr std::size_t max_cells = 128;
constexpr std::size_t max_input_words = 1 + max_rows + max_cells;

void put_i32_le(std::uint8_t* output, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t median_of_matrix(const std::int64_t* input,
                                          std::size_t length,
                                          std::uint8_t* output,
                                          std::size_t capacity) {
    if (input == nullptr || length < 1 || length > max_input_words) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_rows)) return -1;

    const auto row_count = static_cast<std::size_t>(input[0]);
    std::size_t cursor = 1;
    std::size_t value_count = 0;
    std::array<std::int32_t, max_cells> values{};
    for (std::size_t row = 0; row < row_count; ++row) {
        if (cursor >= length) return -1;
        const auto row_length = input[cursor++];
        if (row_length == -1) continue;
        if (row_length < 0 || row_length > static_cast<std::int64_t>(max_cells)) return -1;
        const auto cells = static_cast<std::size_t>(row_length);
        if (cells > max_cells - value_count || cells > length - cursor) return -1;
        for (std::size_t column = 0; column < cells; ++column) {
            const auto value = input[cursor++];
            if (value < INT32_MIN || value > INT32_MAX) return -1;
            values[value_count++] = static_cast<std::int32_t>(value);
        }
    }
    if (cursor != length || value_count == 0) return -1;

    for (std::size_t index = 1; index < value_count; ++index) {
        const auto value = values[index];
        std::size_t position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }

    if (output == nullptr || capacity < 4) return -2;
    std::uint8_t buffer[4];
    put_i32_le(buffer, values[(value_count - 1) / 2]);
    for (std::size_t byte = 0; byte < sizeof buffer; ++byte) output[byte] = buffer[byte];
    return 4;
}
