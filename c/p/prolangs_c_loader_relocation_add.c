/* Copyright (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place. */
#include <stddef.h>
#include <stdint.h>

int64_t prolangs_c_loader_relocation_add(const int64_t *input, size_t length,
                                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > 5) return -1;
    if (input[0] < 1 || input[0] > 6 || input[1] < -65535 || input[1] > 65535) return -1;
    size_t width = ((size_t)input[0] + 1) / 2;
    if (length != 2 + width) return -1;
    uint32_t field = 0;
    for (size_t i = 0; i < width; ++i) {
        if (input[2 + i] < 0 || input[2 + i] > 255) return -1;
        field = field * 256u + (uint32_t)input[2 + i];
    }
    int64_t adjusted = (int64_t)field + input[1];
    if (adjusted < 0) return -1;
    if (capacity < width || output == NULL) return -2;
    uint32_t result = (uint32_t)adjusted;
    for (size_t i = width; i > 0; --i) {
        output[i - 1] = (uint8_t)(result & 255u);
        result >>= 8;
    }
    return (int64_t)width;
}
