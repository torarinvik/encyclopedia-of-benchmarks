#include <stddef.h>
#include <stdint.h>

#define NEXT_PAL_MAX_INPUT INT64_C(9999999999999999)

int64_t next_palindromic_number(const int64_t *values, size_t length) {
    if (values == NULL || length != 1) return -1;
    const int64_t number = values[0];
    if (number < 0 || number > NEXT_PAL_MAX_INPUT) return -1;

    uint8_t digits[17] = {0};
    int64_t remaining = number;
    size_t count = 0;
    do {
        digits[count++] = (uint8_t)(remaining % 10);
        remaining /= 10;
    } while (remaining > 0);
    for (size_t left = 0; left < count / 2; ++left) {
        const size_t right = count - 1 - left;
        const uint8_t swap = digits[left];
        digits[left] = digits[right];
        digits[right] = swap;
    }

    for (size_t left = 0; left < count / 2; ++left)
        digits[count - 1 - left] = digits[left];
    int64_t candidate = 0;
    for (size_t i = 0; i < count; ++i) candidate = candidate * 10 + digits[i];
    if (candidate > number) return candidate;

    const size_t prefix_length = (count + 1) / 2;
    size_t position = prefix_length;
    while (position > 0 && digits[position - 1] == 9) {
        digits[position - 1] = 0;
        --position;
    }
    if (position == 0) {
        int64_t power = 1;
        for (size_t i = 0; i < count; ++i) power *= 10;
        return power + 1;
    }
    ++digits[position - 1];
    for (size_t left = 0; left < count / 2; ++left)
        digits[count - 1 - left] = digits[left];
    candidate = 0;
    for (size_t i = 0; i < count; ++i) candidate = candidate * 10 + digits[i];
    return candidate;
}
