/* Apply an affine substitution over a caller-supplied printable ASCII alphabet. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_VALUES 612
#define MAX_ALPHABET_LENGTH 95
#define MAX_TEXT_LENGTH 512

static int64_t gcd_i64(int64_t left, int64_t right)
{
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static int64_t inverse_mod(int64_t value, int64_t modulus)
{
    for (int64_t candidate = 1; candidate < modulus; ++candidate)
        if ((value * candidate) % modulus == 1) return candidate;
    return -1;
}

int64_t affine_cipher(const int64_t *values, size_t length,
                      uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 7 || length > MAX_INPUT_VALUES) return -1;
    const int64_t mode = values[0], key_a = values[1], key_b = values[2];
    const int64_t alphabet_length_arg = values[3];
    if (mode < 0 || mode > 1 || alphabet_length_arg < 2 ||
        alphabet_length_arg > MAX_ALPHABET_LENGTH) return -1;
    const size_t alphabet_length = (size_t)alphabet_length_arg;
    const size_t text_length_index = 4 + alphabet_length;
    if (length <= text_length_index) return -1;
    const int64_t text_length_arg = values[text_length_index];
    if (key_a < 0 || key_a > 1000000 || key_b < 0 ||
        key_b >= alphabet_length_arg || text_length_arg < 0 ||
        text_length_arg > MAX_TEXT_LENGTH ||
        length != text_length_index + 1 + (size_t)text_length_arg ||
        gcd_i64(key_a, alphabet_length_arg) != 1) return -1;
    const size_t text_length = (size_t)text_length_arg;

    int16_t positions[128];
    for (size_t code = 0; code < 128; ++code) positions[code] = -1;
    for (size_t index = 0; index < alphabet_length; ++index) {
        const int64_t symbol = values[4 + index];
        if (symbol < 32 || symbol > 126 || positions[symbol] != -1) return -1;
        positions[symbol] = (int16_t)index;
    }
    for (size_t index = 0; index < text_length; ++index) {
        const int64_t symbol = values[text_length_index + 1 + index];
        if (symbol < 32 || symbol > 126 || positions[symbol] < 0) return -1;
    }
    if (text_length > output_capacity || (text_length != 0 && output == NULL)) return -2;

    const int64_t multiplier = key_a % alphabet_length_arg;
    const int64_t inverse = mode == 1 ? inverse_mod(multiplier, alphabet_length_arg) : 0;
    for (size_t index = 0; index < text_length; ++index) {
        const int64_t symbol = values[text_length_index + 1 + index];
        const int64_t position = positions[symbol];
        const int64_t mapped = mode == 0
            ? (position * multiplier + key_b) % alphabet_length_arg
            : (((position - key_b + alphabet_length_arg) % alphabet_length_arg) * inverse) % alphabet_length_arg;
        output[index] = (uint8_t)values[4 + (size_t)mapped];
    }
    return (int64_t)text_length;
}
