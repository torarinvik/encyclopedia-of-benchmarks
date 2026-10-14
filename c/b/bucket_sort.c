/* Stable top-byte bucket sort for the full signed 64-bit integer range. */
#include <stddef.h>
#include <stdint.h>

static uint64_t bucket_order_key(int64_t value)
{
    const uint64_t sign_bit = UINT64_C(1) << 63;
    if (value < 0) return sign_bit - 1 - (uint64_t)(-(value + 1));
    return sign_bit + (uint64_t)value;
}

static void bucket_sort_insertion(int64_t *values, size_t base, size_t low, size_t high)
{
    for (size_t index = low + (low < high); index < high; ++index) {
        const int64_t key = values[base + index];
        size_t position = index;
        while (position > low && values[base + position - 1] > key) {
            values[base + position] = values[base + position - 1];
            --position;
        }
        values[base + position] = key;
    }
}

void bucket_sort(int64_t *values, int64_t *scratch, size_t length)
{
    if (length < 2) return;
    for (size_t bucket = 0; bucket < 256; ++bucket) scratch[bucket] = 0;
    for (size_t index = 0; index < length; ++index) {
        const size_t bucket = (size_t)(bucket_order_key(values[index]) >> 56);
        ++scratch[bucket];
    }
    size_t next = 0;
    for (size_t bucket = 0; bucket < 256; ++bucket) {
        const size_t count = (size_t)scratch[bucket];
        scratch[bucket] = (int64_t)next;
        next += count;
    }
    for (size_t index = 0; index < length; ++index) {
        const size_t bucket = (size_t)(bucket_order_key(values[index]) >> 56);
        const size_t destination = (size_t)scratch[bucket]++;
        scratch[256 + destination] = values[index];
    }
    size_t low = 0;
    for (size_t bucket = 0; bucket < 256; ++bucket) {
        const size_t high = (size_t)scratch[bucket];
        bucket_sort_insertion(scratch, 256, low, high);
        low = high;
    }
    for (size_t index = 0; index < length; ++index) values[index] = scratch[256 + index];
}
