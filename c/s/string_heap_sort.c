#include <stddef.h>
#include <stdint.h>

#define MAX_KEYS 64
#define KEY_WIDTH 4
#define MAX_INPUT_LENGTH (1 + MAX_KEYS * KEY_WIDTH)

static void sift_down(uint32_t *keys, size_t root, size_t end) {
    while (root < end / 2) {
        size_t child = root * 2 + 1;
        if (child + 1 < end && keys[child] < keys[child + 1]) ++child;
        if (keys[root] >= keys[child]) break;
        uint32_t t = keys[root]; keys[root] = keys[child]; keys[child] = t;
        root = child;
    }
}

int64_t string_heap_sort(const int64_t *values, size_t length, uint8_t *output, size_t capacity) {
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    int64_t raw_count = values[0];
    if (raw_count < 0 || raw_count > MAX_KEYS || length != 1 + KEY_WIDTH * (size_t)raw_count) return -1;
    size_t count = (size_t)raw_count;
    uint32_t keys[MAX_KEYS];
    for (size_t i = 0; i < count; ++i) {
        uint32_t key = 0;
        for (size_t b = 0; b < KEY_WIDTH; ++b) {
            int64_t byte = values[1 + KEY_WIDTH * i + b];
            if (byte < 0 || byte > 127) return -1;
            key = (key << 8) | (uint32_t)byte;
        }
        keys[i] = key;
    }
    for (size_t start = count / 2; start > 0;) { --start; sift_down(keys, start, count); }
    for (size_t end = count; end > 1;) {
        --end; uint32_t t = keys[0]; keys[0] = keys[end]; keys[end] = t;
        sift_down(keys, 0, end);
    }
    size_t bytes = count * KEY_WIDTH;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t i = 0; i < count; ++i)
        for (size_t b = 0; b < KEY_WIDTH; ++b)
            output[i * KEY_WIDTH + b] = (uint8_t)(keys[i] >> (24 - 8 * b));
    return (int64_t)bytes;
}
