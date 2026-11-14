#include <stddef.h>
#include <stdint.h>

static void put_word(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t j = 0; j < 8; ++j) { output[offset+j] = (uint8_t)(bits & 255u); bits >>= 8; }
}

int64_t lossy_counting_summary(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 66 || input[0] < 2 || input[0] > 16 || input[1] < 0 || input[1] > 64) return -1;
    size_t width = (size_t)input[0], n = (size_t)input[1];
    if (length != 2+n) return -1;
    for (size_t i = 0; i < n; ++i) if (input[2+i] < 0 || input[2+i] > 15) return -1;
    int64_t count[16] = {0}, error[16] = {0};
    for (size_t i = 0; i < n; ++i) {
        size_t item = (size_t)input[2+i];
        int64_t bucket = (int64_t)(i/width+1);
        if (count[item] == 0) error[item] = bucket-1;
        ++count[item];
        if ((i+1)%width == 0) {
            for (size_t j = 0; j < 16; ++j) {
                if (count[j] && count[j]+error[j] <= bucket) { count[j] = 0; error[j] = 0; }
            }
        }
    }
    size_t active = 0;
    for (size_t i = 0; i < 16; ++i) if (count[i]) ++active;
    size_t bytes = 8+24*active;
    if (output == NULL || capacity < bytes) return -2;
    put_word(output, 0, (int64_t)active);
    size_t offset = 8;
    for (size_t i = 0; i < 16; ++i) if (count[i]) {
        put_word(output, offset, (int64_t)i);
        put_word(output, offset+8, count[i]);
        put_word(output, offset+16, error[i]);
        offset += 24;
    }
    return (int64_t)bytes;
}
