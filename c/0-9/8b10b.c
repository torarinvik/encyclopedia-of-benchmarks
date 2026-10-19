#include <stddef.h>
#include <stdint.h>

#define MAX_WORDS 160
#define MAX_OUTPUT_BYTES 18

/* Low bits are source code bits; metadata bits are FLIP, PLUS, and X. */
static const uint16_t raw5[32] = {
    0x0d80, 0x05a2, 0x0c60, 0x0cc0, 0x0ca0, 0x10a2, 0x10c2, 0x10e0,
    0x0d20, 0x1122, 0x1142, 0x1160, 0x1182, 0x11a0, 0x11c0, 0x05e0,
    0x0e20, 0x1222, 0x1242, 0x1260, 0x1282, 0x12a0, 0x12c0, 0x06e0,
    0x1302, 0x1320, 0x1340, 0x0760, 0x0380, 0x07a0, 0x0e80, 0x06a2
};
static const uint16_t raw3[8] = {
    0x0c08, 0x0c04, 0x1009, 0x100c, 0x1011, 0x1014, 0x0018, 0x041c
};

static uint32_t encode_one(uint32_t packed_word, uint32_t *disparity)
{
    const uint32_t data = packed_word & 0xffu;
    const uint32_t k = packed_word >> 8;
    const uint32_t index5 = data >> 3;
    const uint32_t index3 = data & 7u;
    uint32_t lookup5 = raw5[index5];
    uint32_t lookup3 = raw3[index3];
    if (k == 1u && index5 == 7u) lookup5 = 0x04e2u;
    if (k == 1u) {
        if (index3 >= 2u && index3 <= 5u)
            lookup3 = (lookup3 & ~0x1000u) | 0x0800u;
        else if (index3 == 7u)
            lookup3 = 0x040du;
    }

    uint32_t result;
    uint32_t disparity1;
    if ((lookup5 & 0x1000u) != 0u) {
        result = lookup5 & 0x03e2u;
        disparity1 = *disparity;
    } else {
        const uint32_t code5 = lookup5 & 0x03e2u;
        const uint32_t plus5 = (lookup5 & 0x0800u) != 0u;
        result = (*disparity == plus5) ? code5 : code5 ^ 0x03e2u;
        disparity1 = *disparity ^ ((lookup5 & 0x0400u) != 0u);
    }

    if ((lookup3 & 0x1000u) != 0u) {
        result |= lookup3 & 0x001du;
        *disparity = disparity1;
    } else {
        const uint32_t code3 = lookup3 & 0x001du;
        const uint32_t plus3 = (lookup3 & 0x0800u) != 0u;
        result |= (disparity1 == plus3) ? code3 : code3 ^ 0x001du;
        *disparity = disparity1 ^ ((lookup3 & 0x0400u) != 0u);
    }
    return result;
}

static size_t append_line(uint32_t value, uint8_t *staged, size_t used)
{
    static const uint8_t hex[] = "0123456789ABCDEF";
    for (size_t digit = 0; digit < 8; ++digit) {
        const uint32_t shift = (uint32_t)((7u - digit) * 4u);
        staged[used++] = hex[(value >> shift) & 15u];
    }
    staged[used++] = (uint8_t)'\n';
    return used;
}

int64_t versabench_8b10b(const int64_t *values, size_t length,
                         uint8_t *output, size_t output_capacity)
{
    if (length > MAX_WORDS || (length != 0u && values == NULL)) return -1;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > 511) return -1;

    const size_t sample_count = length == 0u ? 0u : 1u + (length - 1u) / 128u;
    const size_t required = sample_count * 9u;
    if (required != 0u && (output == NULL || output_capacity < required)) return -2;

    uint8_t staged[MAX_OUTPUT_BYTES];
    size_t used = 0;
    uint32_t disparity = 0;
    for (size_t pass = 0; pass < length; ++pass) {
        for (size_t index = 0; index < length; ++index) {
            const uint32_t encoded = encode_one((uint32_t)values[index], &disparity);
            if (pass + 1u == length && index % 128u == 0u)
                used = append_line(encoded, staged, used);
        }
    }

    for (size_t index = 0; index < required; ++index) output[index] = staged[index];
    return (int64_t)used;
}
