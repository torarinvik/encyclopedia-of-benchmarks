#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_INPUT_BYTES = 5000;
constexpr std::size_t MAX_INPUT_VALUES = MAX_INPUT_BYTES + 1;
constexpr std::size_t CHUNK_WIDTH = 50;
constexpr std::size_t MAX_OUTPUT_BYTES = 10;
}

extern "C" std::int64_t problem13_chunks(const std::int64_t *values,
                                         std::size_t length,
                                         std::uint8_t *output,
                                         std::size_t capacity)
{
    if (values == nullptr || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (values[0] < 1 || values[0] > static_cast<std::int64_t>(MAX_INPUT_BYTES) ||
        static_cast<std::size_t>(values[0]) != length - 1) return -1;

    const auto byte_length = static_cast<std::size_t>(values[0]);
    for (std::size_t index = 0; index < byte_length; ++index) {
        if (values[index + 1] < '0' || values[index + 1] > '9') return -1;
    }

    const auto width = byte_length < CHUNK_WIDTH ? byte_length : CHUNK_WIDTH;
    std::uint8_t reversed[CHUNK_WIDTH + 2];
    std::size_t reversed_length = 0;
    std::int64_t carry = 0;
    for (std::size_t remaining = width; remaining > 0; --remaining) {
        const auto position = remaining - 1;
        std::int64_t column = carry;
        for (std::size_t start = 0; start < byte_length; start += CHUNK_WIDTH) {
            const auto chunk_length = byte_length - start < CHUNK_WIDTH
                ? byte_length - start : CHUNK_WIDTH;
            if (position < chunk_length) {
                column += values[1 + start + position] - '0';
            }
        }
        reversed[reversed_length++] = static_cast<std::uint8_t>(column % 10);
        carry = column / 10;
    }
    while (carry > 0) {
        reversed[reversed_length++] = static_cast<std::uint8_t>(carry % 10);
        carry /= 10;
    }

    const auto output_length = reversed_length < MAX_OUTPUT_BYTES
        ? reversed_length : MAX_OUTPUT_BYTES;
    if (output == nullptr || capacity < output_length) return -2;
    for (std::size_t index = 0; index < output_length; ++index) {
        output[index] = static_cast<std::uint8_t>('0' + reversed[reversed_length - 1 - index]);
    }
    return static_cast<std::int64_t>(output_length);
}
