/* Arrange ASCII letters in zigzag rows and read them row by row. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 1025;
constexpr std::int64_t max_rows = 1024;

bool is_ascii_letter(std::int64_t value) noexcept {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}
}

extern "C" std::int64_t zigzag_conversion(const std::int64_t *values, std::size_t length,
        std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length == 0 || length > max_input_length || values == nullptr) return -1;
    const auto requested_rows = values[0];
    if (requested_rows < 1 || requested_rows > max_rows) return -1;
    const std::size_t text_length = length - 1;
    for (std::size_t index = 0; index < text_length; ++index)
        if (!is_ascii_letter(values[index + 1])) return -1;
    if (output_capacity < text_length || (text_length != 0 && output == nullptr)) return -2;
    if (text_length == 0) return 0;
    const auto rows = static_cast<std::size_t>(requested_rows);
    if (rows == 1 || rows >= text_length) {
        for (std::size_t index = 0; index < text_length; ++index)
            output[index] = static_cast<std::uint8_t>(values[index + 1]);
        return static_cast<std::int64_t>(text_length);
    }
    const std::size_t cycle = 2 * (rows - 1);
    std::size_t written = 0;
    for (std::size_t row = 0; row < rows; ++row) {
        std::size_t index = row;
        std::size_t step = row == 0 || row + 1 == rows ? cycle : cycle - 2 * row;
        while (index < text_length) {
            output[written++] = static_cast<std::uint8_t>(values[index + 1]);
            index += step;
            if (row > 0 && row + 1 < rows) step = cycle - step;
        }
    }
    return static_cast<std::int64_t>(written);
}
