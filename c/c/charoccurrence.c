#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT 128
#define MAX_OUTPUT 1024

static size_t append_decimal(uint8_t *buffer, size_t offset, size_t value) {
    uint8_t digits[3];
    size_t count = 0;
    do {
        digits[count++] = (uint8_t)('0' + value % 10);
        value /= 10;
    } while (value != 0);
    while (count != 0) {
        buffer[offset++] = digits[--count];
    }
    return offset;
}

int64_t charoccurrence(const int64_t *values, size_t length,
                       uint8_t *output, size_t output_capacity) {
    if (length > MAX_INPUT || (length != 0 && values == NULL)) {
        return -1;
    }
    size_t counts[128] = {0};
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 127) {
            return -1;
        }
        ++counts[(size_t)values[index]];
    }

    uint8_t encoded[MAX_OUTPUT];
    size_t used = 0;
    for (size_t codepoint = 0; codepoint < 128; ++codepoint) {
        if (counts[codepoint] == 0) {
            continue;
        }
        if (used != 0) {
            encoded[used++] = ',';
        }
        used = append_decimal(encoded, used, codepoint);
        encoded[used++] = '=';
        used = append_decimal(encoded, used, counts[codepoint]);
    }
    if (used > output_capacity) {
        return -2;
    }
    if (used != 0 && output == NULL) {
        return -2;
    }
    for (size_t index = 0; index < used; ++index) {
        output[index] = encoded[index];
    }
    return (int64_t)used;
}
