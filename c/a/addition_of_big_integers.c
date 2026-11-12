#include <stddef.h>
#include <stdint.h>

typedef struct {
    size_t digit_start;
    size_t digit_count;
    int negative;
} DecimalOperand;

static int parse_operand(const int64_t *input, size_t start, size_t text_length,
                         DecimalOperand *operand) {
    if (text_length == 0 || text_length > 33) return 0;
    int negative = input[start] == 45;
    size_t digit_start = start + (negative ? 1 : 0);
    size_t digit_count = text_length - (negative ? 1 : 0);
    if (digit_count == 0 || digit_count > 32) return 0;
    for (size_t i = 0; i < digit_count; ++i) {
        int64_t byte = input[digit_start + i];
        if (byte < 48 || byte > 57) return 0;
        if (i == 0 && digit_count > 1 && byte == 48) return 0;
    }
    if (negative && digit_count == 1 && input[digit_start] == 48) return 0;
    operand->digit_start = digit_start;
    operand->digit_count = digit_count;
    operand->negative = negative;
    return 1;
}

static int compare_magnitude(const int64_t *input, DecimalOperand a,
                             DecimalOperand b) {
    if (a.digit_count != b.digit_count)
        return a.digit_count > b.digit_count ? 1 : -1;
    for (size_t i = 0; i < a.digit_count; ++i) {
        int64_t da = input[a.digit_start + i];
        int64_t db = input[b.digit_start + i];
        if (da != db) return da > db ? 1 : -1;
    }
    return 0;
}

int64_t addition_of_big_integers(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > 68) return -1;
    int64_t raw_a = input[0], raw_b = input[1];
    if (raw_a < 1 || raw_a > 33 || raw_b < 1 || raw_b > 33) return -1;
    size_t len_a = (size_t)raw_a, len_b = (size_t)raw_b;
    if (length != 2 + len_a + len_b) return -1;
    DecimalOperand a, b;
    if (!parse_operand(input, 2, len_a, &a) ||
        !parse_operand(input, 2 + len_a, len_b, &b)) return -1;

    uint8_t reversed[33] = {0};
    size_t digits = 0;
    int negative = 0;
    if (a.negative == b.negative) {
        negative = a.negative;
        size_t width = a.digit_count > b.digit_count ? a.digit_count : b.digit_count;
        int carry = 0;
        for (size_t offset = 0; offset < width; ++offset) {
            int da = offset < a.digit_count
                ? (int)(input[a.digit_start + a.digit_count - 1 - offset] - 48) : 0;
            int db = offset < b.digit_count
                ? (int)(input[b.digit_start + b.digit_count - 1 - offset] - 48) : 0;
            int total = da + db + carry;
            reversed[digits++] = (uint8_t)(total % 10);
            carry = total / 10;
        }
        if (carry != 0) reversed[digits++] = (uint8_t)carry;
    } else {
        int order = compare_magnitude(input, a, b);
        if (order == 0) {
            reversed[0] = 0;
            digits = 1;
        } else {
            DecimalOperand larger = order > 0 ? a : b;
            DecimalOperand smaller = order > 0 ? b : a;
            negative = larger.negative;
            int borrow = 0;
            for (size_t offset = 0; offset < larger.digit_count; ++offset) {
                int da = (int)(input[larger.digit_start + larger.digit_count - 1 - offset] - 48);
                int db = offset < smaller.digit_count
                    ? (int)(input[smaller.digit_start + smaller.digit_count - 1 - offset] - 48) : 0;
                int digit = da - db - borrow;
                borrow = digit < 0;
                reversed[digits++] = (uint8_t)(digit < 0 ? digit + 10 : digit);
            }
            while (digits > 1 && reversed[digits - 1] == 0) --digits;
        }
    }

    size_t output_length = digits + (negative ? 1 : 0);
    if (output == NULL || capacity < output_length) return -2;
    size_t cursor = 0;
    if (negative) output[cursor++] = 45;
    for (size_t i = 0; i < digits; ++i)
        output[cursor++] = (uint8_t)(48 + reversed[digits - 1 - i]);
    return (int64_t)output_length;
}
