/* Bounded port of BitBench five11's MSB-first packet decoder and channel sum. */
#include <stddef.h>
#include <stdint.h>

#define FIVE11_MAX_INPUT 13523
#define FIVE11_MAX_PARSEABLE_INPUT 13524
#define FIVE11_MAX_PACKETS 451
#define FIVE11_REPETITIONS 10000

static int64_t read_bits(const int64_t *values, size_t length,
                         size_t bit_offset, unsigned width) {
    const size_t bit_length = length * 8;
    if (bit_offset > bit_length || width > bit_length - bit_offset) return -1;
    const size_t byte_offset = bit_offset >> 3;
    const unsigned start = (unsigned)(bit_offset & 7u);
    const size_t byte_count = (start + width + 7u) >> 3;
    uint32_t window = 0;
    for (size_t index = 0; index < byte_count; ++index)
        window = (window << 8) | (uint32_t)values[byte_offset + index];
    const unsigned shift = (unsigned)(byte_count * 8u) - start - width;
    const uint32_t mask = (UINT32_C(1) << width) - 1u;
    return (int64_t)((window >> shift) & mask);
}

static int64_t decode_sum(const int64_t *values, size_t length) {
    const int64_t packet_count = read_bits(values, length, 0, 16);
    if (packet_count < 0 || packet_count > FIVE11_MAX_PACKETS) return -1;
    size_t bit_offset = 16;
    int64_t total = 0;
    for (int64_t packet = 0; packet < packet_count; ++packet) {
        const int64_t channels = read_bits(values, length, bit_offset, 5);
        if (channels < 0) return -1;
        bit_offset += 5;
        for (int64_t channel = 0; channel < channels; ++channel) {
            const int64_t value = read_bits(values, length, bit_offset, 11);
            if (value < 0) return -1;
            total += value;
            bit_offset += 11;
        }
        const size_t packet_bits = (size_t)(5 + 11 * channels);
        bit_offset += (8u - (packet_bits & 7u)) & 7u;
        if (bit_offset > length * 8) return -1;
    }
    return total;
}

int64_t five11(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > FIVE11_MAX_PARSEABLE_INPUT ||
        length > FIVE11_MAX_INPUT) return -1;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > 255) return -1;
    int64_t result = 0;
    for (int repetition = 0; repetition < FIVE11_REPETITIONS; ++repetition) {
        result = decode_sum(values, length);
        if (result < 0) return -1;
    }
    return result;
}
