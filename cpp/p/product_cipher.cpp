#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_INPUT_VALUES = 259;
constexpr std::size_t MAX_TEXT_LENGTH = 256;
constexpr std::size_t MAX_COLUMNS = 64;
constexpr std::size_t MAX_OUTPUT_BYTES = 315;
}

extern "C" std::int64_t product_cipher(const std::int64_t* input, std::size_t length,
                                        std::uint8_t* output, std::size_t output_capacity)
{
    if (input == nullptr || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_COLUMNS) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(MAX_TEXT_LENGTH)) return -1;

    const std::size_t columns = static_cast<std::size_t>(input[0]);
    const std::size_t text_length = static_cast<std::size_t>(input[1]);
    if (length != 2 + text_length) return -1;
    for (std::size_t index = 0; index < text_length; ++index) {
        const std::int64_t byte = input[2 + index];
        if (byte < 0 || byte > 127 || byte == 10 || byte == 13) return -1;
    }

    const std::size_t padded_length = text_length == 0
        ? 0
        : ((text_length + columns - 1) / columns) * columns;
    if (padded_length > MAX_OUTPUT_BYTES) return -1;
    if (padded_length == 0) return 0;
    if (output == nullptr || output_capacity < padded_length) return -2;

    std::uint8_t padded[MAX_OUTPUT_BYTES] = {};
    for (std::size_t index = 0; index < text_length; ++index)
        padded[index] = static_cast<std::uint8_t>(input[2 + index] + 5);
    for (std::size_t index = text_length; index < padded_length; ++index)
        padded[index] = static_cast<std::uint8_t>('/');
    std::size_t written = 0;
    const std::size_t rows = padded_length / columns;
    for (std::size_t column = 0; column < columns; ++column) {
        for (std::size_t row = 0; row < rows; ++row)
            output[written++] = padded[column + row * columns];
    }
    return static_cast<std::int64_t>(written);
}
