#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_TEXT = 256;
constexpr std::size_t MAX_INPUT = 259;
}

extern "C" std::int64_t transposition_cipher(const std::int64_t *input, std::size_t length,
                                              std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 6 || length > MAX_INPUT) return -1;
    const auto mode = input[0], key64 = input[1], n64 = input[2];
    if ((mode != 0 && mode != 1) || n64 < 3 || n64 > static_cast<std::int64_t>(MAX_TEXT) ||
        key64 < 2 || key64 >= n64 || length != 3 + static_cast<std::size_t>(n64)) return -1;
    const auto key = static_cast<std::size_t>(key64), n = static_cast<std::size_t>(n64);
    for (std::size_t i = 0; i < n; ++i) if (input[3 + i] < 0 || input[3 + i] > 127) return -1;
    if (output == nullptr || output_capacity < n) return -2;

    std::uint8_t transformed[MAX_TEXT];
    if (mode == 0) {
        std::size_t written = 0;
        for (std::size_t column = 0; column < key; ++column)
            for (std::size_t index = column; index < n; index += key)
                transformed[written++] = static_cast<std::uint8_t>(input[3 + index]);
    } else {
        const std::size_t columns = (n + key - 1) / key;
        const std::size_t shaded = columns * key - n;
        const std::size_t final_column_rows = key - shaded;
        std::size_t offsets[MAX_TEXT], seen[MAX_TEXT]{};
        std::size_t total = 0;
        for (std::size_t column = 0; column < columns; ++column) {
            offsets[column] = total;
            total += column + 1 == columns ? final_column_rows : key;
        }
        std::size_t row = 0, column = 0;
        for (std::size_t i = 0; i < n; ++i) {
            transformed[offsets[column] + seen[column]++] = static_cast<std::uint8_t>(input[3 + i]);
            ++column;
            if (column == columns || (column == columns - 1 && row >= final_column_rows)) {
                column = 0;
                ++row;
            }
        }
    }
    for (std::size_t i = 0; i < n; ++i) output[i] = transformed[i];
    return static_cast<std::int64_t>(n);
}
