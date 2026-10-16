#include <cstddef>
#include <cstdint>

namespace {
bool parse_component(const std::int64_t* input, std::size_t start, std::size_t end,
                     std::int64_t& value) {
    bool negative = false;
    if (start < end && input[start] == 45) { negative = true; ++start; }
    if (start == end) return false;
    std::int64_t magnitude = 0;
    for (std::size_t index = start; index < end; ++index) {
        if (input[index] < 48 || input[index] > 57) return false;
        const std::int64_t digit = input[index] - 48;
        if (magnitude > (32767 - digit) / 10) return false;
        magnitude = magnitude * 10 + digit;
    }
    value = negative ? -magnitude : magnitude;
    return true;
}

bool parse_complex(const std::int64_t* input, std::size_t start, std::size_t length,
                   std::int64_t& real, std::int64_t& imaginary) {
    if (length < 4 || length > 64 || input[start + length - 1] != 105) return false;
    std::size_t separator = length;
    for (std::size_t index = 0; index + 1 < length; ++index) {
        if (input[start + index] == 43) {
            if (separator != length) return false;
            separator = index;
        }
    }
    return separator != length
        && parse_component(input, start, start + separator, real)
        && parse_component(input, start + separator + 1, start + length - 1, imaginary);
}

std::size_t decimal_length(std::int64_t value) {
    std::size_t length = value < 0 ? 1 : 0;
    std::int64_t magnitude = value < 0 ? -value : value;
    do { ++length; magnitude /= 10; } while (magnitude != 0);
    return length;
}

std::size_t append_decimal(std::uint8_t* output, std::size_t index, std::int64_t value) {
    if (value < 0) { output[index++] = 45; value = -value; }
    const std::size_t start = index;
    if (value == 0) { output[index] = 48; return index + 1; }
    while (value != 0) { output[index++] = static_cast<std::uint8_t>(48 + value % 10); value /= 10; }
    for (std::size_t left = start, right = index - 1; left < right; ++left, --right) {
        const auto temporary = output[left]; output[left] = output[right]; output[right] = temporary;
    }
    return index;
}
}

extern "C" std::int64_t complex_number_multiply(const std::int64_t* input, std::size_t length,
                                                std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > 130) return -1;
    const auto raw_left_length = input[0], raw_right_length = input[1];
    if (raw_left_length < 4 || raw_left_length > 64 || raw_right_length < 4 || raw_right_length > 64) return -1;
    const auto left_length = static_cast<std::size_t>(raw_left_length);
    const auto right_length = static_cast<std::size_t>(raw_right_length);
    if (length != 2 + left_length + right_length) return -1;
    for (std::size_t index = 2; index < length; ++index)
        if (input[index] < 0 || input[index] > 127) return -1;

    std::int64_t left_real, left_imaginary, right_real, right_imaginary;
    if (!parse_complex(input, 2, left_length, left_real, left_imaginary)
        || !parse_complex(input, 2 + left_length, right_length, right_real, right_imaginary)) return -1;
    const std::int64_t real = left_real * right_real - left_imaginary * right_imaginary;
    const std::int64_t imaginary = left_real * right_imaginary + left_imaginary * right_real;
    const std::size_t needed = decimal_length(real) + decimal_length(imaginary) + 2;
    if (output == nullptr || capacity < needed) return -2;

    std::size_t written = append_decimal(output, 0, real);
    output[written++] = 43;
    written = append_decimal(output, written, imaginary);
    output[written++] = 105;
    return static_cast<std::int64_t>(written);
}
