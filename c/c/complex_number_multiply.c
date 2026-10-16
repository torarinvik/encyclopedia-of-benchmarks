#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 64
#define MAX_INPUT_LENGTH 130
#define MAX_COMPONENT 32767

static int parse_component(const int64_t *input, size_t start, size_t end, int64_t *value) {
    int negative = 0;
    if (start < end && input[start] == 45) {
        negative = 1;
        ++start;
    }
    if (start == end) return 0;

    int64_t magnitude = 0;
    for (size_t index = start; index < end; ++index) {
        if (input[index] < 48 || input[index] > 57) return 0;
        const int64_t digit = input[index] - 48;
        if (magnitude > (MAX_COMPONENT - digit) / 10) return 0;
        magnitude = magnitude * 10 + digit;
    }
    *value = negative ? -magnitude : magnitude;
    return 1;
}

static int parse_complex(const int64_t *input, size_t start, size_t length,
                         int64_t *real, int64_t *imaginary) {
    if (length < 4 || length > MAX_TEXT_LENGTH || input[start + length - 1] != 105) return 0;
    size_t separator = length;
    for (size_t index = 0; index + 1 < length; ++index) {
        if (input[start + index] == 43) {
            if (separator != length) return 0;
            separator = index;
        }
    }
    if (separator == length) return 0;
    return parse_component(input, start, start + separator, real)
        && parse_component(input, start + separator + 1, start + length - 1, imaginary);
}

static size_t decimal_length(int64_t value) {
    size_t length = value < 0 ? 1 : 0;
    int64_t magnitude = value < 0 ? -value : value;
    do {
        ++length;
        magnitude /= 10;
    } while (magnitude != 0);
    return length;
}

static size_t append_decimal(uint8_t *output, size_t index, int64_t value) {
    if (value < 0) {
        output[index++] = 45;
        value = -value;
    }
    const size_t start = index;
    if (value == 0) {
        output[index++] = 48;
        return index;
    }
    while (value != 0) {
        output[index++] = (uint8_t)(48 + value % 10);
        value /= 10;
    }
    for (size_t left = start, right = index - 1; left < right; ++left, --right) {
        const uint8_t temporary = output[left];
        output[left] = output[right];
        output[right] = temporary;
    }
    return index;
}

int64_t complex_number_multiply(const int64_t *input, size_t length,
                                uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_left_length = input[0], raw_right_length = input[1];
    if (raw_left_length < 4 || raw_left_length > MAX_TEXT_LENGTH
        || raw_right_length < 4 || raw_right_length > MAX_TEXT_LENGTH) return -1;
    const size_t left_length = (size_t)raw_left_length;
    const size_t right_length = (size_t)raw_right_length;
    if (length != 2 + left_length + right_length) return -1;
    for (size_t index = 2; index < length; ++index)
        if (input[index] < 0 || input[index] > 127) return -1;

    int64_t left_real, left_imaginary, right_real, right_imaginary;
    if (!parse_complex(input, 2, left_length, &left_real, &left_imaginary)
        || !parse_complex(input, 2 + left_length, right_length, &right_real, &right_imaginary)) return -1;

    const int64_t real = left_real * right_real - left_imaginary * right_imaginary;
    const int64_t imaginary = left_real * right_imaginary + left_imaginary * right_real;
    const size_t needed = decimal_length(real) + decimal_length(imaginary) + 2;
    if (output == NULL || output_capacity < needed) return -2;

    size_t written = append_decimal(output, 0, real);
    output[written++] = 43;
    written = append_decimal(output, written, imaginary);
    output[written++] = 105;
    return (int64_t)written;
}
