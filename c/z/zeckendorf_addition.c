#include <stddef.h>
#include <stdint.h>

enum { MAX_BITS = 64, MAX_PARSEABLE = 131, MAX_OUTPUT = 66 };

static int canonical(const int64_t *bits, size_t length) {
    if (length == 1 && bits[0] == 0) return 1;
    if (length == 0 || bits[0] != 1) return 0;
    for (size_t i = 0; i < length; ++i) {
        if (bits[i] != 0 && bits[i] != 1) return 0;
        if (i + 1 < length && bits[i] == 1 && bits[i + 1] == 1) return 0;
    }
    return 1;
}

static void stage_one(uint8_t *d, size_t n) {
    for (size_t i = 0; i + 3 < n; ++i) {
        if (d[i] == 0 && d[i + 1] == 2 && d[i + 2] == 0) {
            d[i] = 1; d[i + 1] = 0; d[i + 2] = 0; ++d[i + 3];
        } else if (d[i] == 0 && d[i + 1] == 3 && d[i + 2] == 0) {
            d[i] = 1; d[i + 1] = 1; d[i + 2] = 0; ++d[i + 3];
        } else if (d[i] == 0 && d[i + 1] == 2 && d[i + 2] == 1) {
            d[i] = 1; d[i + 1] = 1; d[i + 2] = 0;
        } else if (d[i] == 0 && d[i + 1] == 1 && d[i + 2] == 2) {
            d[i] = 1; d[i + 1] = 0; d[i + 2] = 1;
        }
    }
    if (n >= 3 && d[n - 3] == 0 && d[n - 2] == 3 && d[n - 1] == 0) {
        d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 1;
    } else if (n >= 3 && d[n - 3] == 0 && d[n - 2] == 2 && d[n - 1] == 0) {
        d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1;
    } else if (n >= 4 && d[n - 4] == 0 && d[n - 3] == 1 && d[n - 2] == 2 && d[n - 1] == 0) {
        d[n - 4] = 1; d[n - 3] = 0; d[n - 2] = 1; d[n - 1] = 0;
    } else if (n >= 3 && d[n - 3] == 0 && d[n - 2] == 2 && d[n - 1] == 1) {
        d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 0;
    }
    if (n >= 2 && d[n - 2] == 0 && d[n - 1] == 3) {
        d[n - 2] = 1; d[n - 1] = 1;
    } else if (n >= 2 && d[n - 2] == 0 && d[n - 1] == 2) {
        d[n - 2] = 1; d[n - 1] = 0;
    } else if (n >= 3 && d[n - 3] == 0 && d[n - 2] == 1 && d[n - 1] == 2) {
        d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1;
    }
}

int64_t zeckendorf_addition(const int64_t *input, size_t length,
    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_PARSEABLE) return -1;
    const int64_t first_n = input[0];
    if (first_n < 1 || first_n > MAX_BITS) return -1;
    const size_t second_n_index = (size_t)first_n + 1;
    if (second_n_index >= length) return -1;
    const int64_t second_n = input[second_n_index];
    if (second_n < 1 || second_n > MAX_BITS) return -1;
    if (length != second_n_index + (size_t)second_n + 1) return -1;
    const int64_t *first = input + 1;
    const int64_t *second = input + second_n_index + 1;
    if (!canonical(first, (size_t)first_n) || !canonical(second, (size_t)second_n)) return -1;

    const size_t width = (size_t)(first_n > second_n ? first_n : second_n);
    const size_t first_offset = width - (size_t)first_n;
    const size_t second_offset = width - (size_t)second_n;
    uint8_t digits[MAX_OUTPUT] = {0};
    size_t digit_count = width + 1;
    for (size_t i = 0; i < width; ++i) {
        const uint8_t a = i < first_offset ? 0 : (uint8_t)first[i - first_offset];
        const uint8_t b = i < second_offset ? 0 : (uint8_t)second[i - second_offset];
        digits[i + 1] = (uint8_t)(a + b);
    }
    stage_one(digits, digit_count);

    for (size_t i = digit_count; i > 0; --i) digits[i] = digits[i - 1];
    digits[0] = 0;
    ++digit_count;
    for (size_t i = digit_count - 2; i > 0; --i) {
        const size_t start = i - 1;
        if (digits[start] == 0 && digits[start + 1] == 1 && digits[start + 2] == 1) {
            digits[start] = 1; digits[start + 1] = 0; digits[start + 2] = 0;
        }
    }
    for (size_t i = 0; i + 2 < digit_count; ++i) {
        if (digits[i] == 0 && digits[i + 1] == 1 && digits[i + 2] == 1) {
            digits[i] = 1; digits[i + 1] = 0; digits[i + 2] = 0;
        }
    }
    size_t first_output = 0;
    while (first_output + 1 < digit_count && digits[first_output] == 0) ++first_output;
    const size_t required = digit_count - first_output;
    if (output == NULL || capacity < required) return -2;
    for (size_t i = 0; i < required; ++i) output[i] = (uint8_t)('0' + digits[first_output + i]);
    return (int64_t)required;
}
