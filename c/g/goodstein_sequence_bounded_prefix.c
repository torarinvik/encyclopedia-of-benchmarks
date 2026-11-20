#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_WORDS 3
#define MAX_START 4
#define MAX_TRANSITIONS 16
#define MAX_TERMS 17

static int64_t small_power(int64_t base, int64_t exponent) {
    int64_t result = 1;
    for (int64_t index = 0; index < exponent; ++index) result *= base;
    return result;
}

static int64_t rebase_hereditary(int64_t value, int64_t base, int64_t raised_base) {
    if (value == 0) return 0;
    int64_t result = 0;
    int64_t place = 1;
    int64_t exponent = 0;
    while (place <= value) {
        const int64_t digit = (value / place) % base;
        if (digit != 0) {
            const int64_t raised_exponent = rebase_hereditary(exponent, base, raised_base);
            result += digit * small_power(raised_base, raised_exponent);
        }
        place *= base;
        ++exponent;
    }
    return result;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t goodstein_sequence_bounded_prefix(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_WORDS || length != 2) return -1;
    const int64_t start = input[0];
    const int64_t transitions = input[1];
    if (start < 0 || start > MAX_START || transitions < 0 || transitions > MAX_TRANSITIONS) return -1;

    int64_t terms[MAX_TERMS] = {0};
    size_t count = 1;
    terms[0] = start;
    int64_t current = start;
    int64_t base = 2;
    for (int64_t step = 0; step < transitions && current != 0; ++step) {
        current = rebase_hereditary(current, base, base + 1) - 1;
        ++base;
        terms[count++] = current;
    }

    const size_t output_bytes = (count + 1) * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    store_i64_le(output, 0, (int64_t)count);
    for (size_t index = 0; index < count; ++index)
        store_i64_le(output, (index + 1) * 8, terms[index]);
    return (int64_t)output_bytes;
}
