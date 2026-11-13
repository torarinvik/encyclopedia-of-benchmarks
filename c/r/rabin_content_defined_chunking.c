#include <stddef.h>
#include <stdint.h>

static uint16_t cdc_reduce(uint32_t value) {
    for (int bit = 31; bit >= 16; --bit)
        if (value & (UINT32_C(1) << bit)) value ^= UINT32_C(0x1100b) << (bit - 16);
    return (uint16_t)value;
}

int64_t rabin_content_defined_chunking(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (!input || length < 1 || length > 65 || input[0] < 0 || input[0] > 64) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 255) return -1;
    uint16_t outgoing[256];
    for (size_t i = 0; i < 256; ++i) outgoing[i] = cdc_reduce((uint32_t)i << 24);
    uint16_t fingerprint = 0;
    uint8_t boundaries[64];
    size_t count = 0;
    for (size_t i = 0; i < n; ++i) {
        fingerprint = cdc_reduce(((uint32_t)fingerprint << 8) | (uint32_t)input[i + 1]);
        if (i >= 4) fingerprint ^= outgoing[(size_t)input[i - 3]];
        if ((fingerprint & 7u) == 0) boundaries[count++] = (uint8_t)(i + 1);
    }
    if (n && (!count || boundaries[count - 1] != n)) boundaries[count++] = (uint8_t)n;
    if (!output || capacity < count) return -2;
    for (size_t i = 0; i < count; ++i) output[i] = boundaries[i];
    return (int64_t)count;
}
