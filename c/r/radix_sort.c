/* Stable LSD radix sort for the full signed 64-bit integer range. */
#include <stddef.h>
#include <stdint.h>

static uint64_t radix_order_key(int64_t value)
{
    const uint64_t sign_bit = UINT64_C(1) << 63;
    if (value < 0) {
        return sign_bit - 1 - (uint64_t)(-(value + 1));
    }
    return sign_bit + (uint64_t)value;
}

void radix_sort(int64_t *values, int64_t *scratch, size_t length)
{
    if (length < 2) return;
    int64_t *counts = scratch;
    int64_t *output = scratch + 256;
    for (unsigned pass = 0; pass < 8; ++pass) {
        for (size_t bucket = 0; bucket < 256; ++bucket) counts[bucket] = 0;
        const unsigned shift = pass * 8;
        for (size_t index = 0; index < length; ++index) {
            const size_t bucket = (size_t)((radix_order_key(values[index]) >> shift) & UINT64_C(255));
            ++counts[bucket];
        }
        size_t next = 0;
        for (size_t bucket = 0; bucket < 256; ++bucket) {
            const size_t count = (size_t)counts[bucket];
            counts[bucket] = (int64_t)next;
            next += count;
        }
        for (size_t index = 0; index < length; ++index) {
            const size_t bucket = (size_t)((radix_order_key(values[index]) >> shift) & UINT64_C(255));
            const size_t destination = (size_t)counts[bucket]++;
            output[destination] = values[index];
        }
        for (size_t index = 0; index < length; ++index) values[index] = output[index];
    }
}
