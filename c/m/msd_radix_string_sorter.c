#include <stddef.h>
#include <stdint.h>

#define MAX_STRINGS 256u
#define MAX_STRING_LENGTH 32u
#define MAX_INPUT_VALUES (1u + MAX_STRINGS * (1u + MAX_STRING_LENGTH) + 1u)
#define INVALID_RESULT (-INT64_C(1))
#define FNV_OFFSET_BASIS UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)

typedef struct {
    uint8_t bytes[MAX_STRING_LENGTH];
    size_t length;
} EncodedString;

static size_t bucket_for(const EncodedString *value, size_t digit)
{
    if (digit >= value->length) return 0u;
    return (size_t)value->bytes[digit] + 1u;
}

/* Stable MSD distribution. Bucket 0 represents end-of-string, before all
 * byte values; buckets 1..256 represent bytes 0..255.
 */
static void msd_sort(EncodedString *values, EncodedString *auxiliary,
                     size_t low, size_t high, size_t digit)
{
    if (high - low < 2u || digit >= MAX_STRING_LENGTH) return;

    size_t counts[257] = {0};
    for (size_t index = low; index < high; ++index)
        ++counts[bucket_for(&values[index], digit)];

    size_t starts[257];
    size_t next[257];
    size_t position = low;
    for (size_t bucket = 0; bucket < 257u; ++bucket) {
        starts[bucket] = position;
        next[bucket] = position;
        position += counts[bucket];
    }

    for (size_t index = low; index < high; ++index) {
        const size_t bucket = bucket_for(&values[index], digit);
        auxiliary[next[bucket]++] = values[index];
    }
    for (size_t index = low; index < high; ++index)
        values[index] = auxiliary[index];

    for (size_t bucket = 1u; bucket < 257u; ++bucket) {
        const size_t bucket_low = starts[bucket];
        const size_t bucket_high = bucket_low + counts[bucket];
        if (bucket_high - bucket_low > 1u)
            msd_sort(values, auxiliary, bucket_low, bucket_high, digit + 1u);
    }
}

static uint64_t fnv1a_add(uint64_t hash, uint8_t byte)
{
    return (hash ^ (uint64_t)byte) * FNV_PRIME;
}

int64_t msd_radix_string_sorter(const int64_t *input, size_t length)
{
    if (input == NULL || length == 0u || length > MAX_INPUT_VALUES)
        return INVALID_RESULT;

    const int64_t raw_count = input[0];
    if (raw_count < 0 || raw_count > (int64_t)MAX_STRINGS)
        return INVALID_RESULT;
    const size_t count = (size_t)raw_count;

    EncodedString values[MAX_STRINGS];
    EncodedString auxiliary[MAX_STRINGS];
    size_t position = 1u;
    for (size_t string_index = 0; string_index < count; ++string_index) {
        if (position >= length) return INVALID_RESULT;
        const int64_t raw_length = input[position++];
        if (raw_length < 0 || raw_length > (int64_t)MAX_STRING_LENGTH)
            return INVALID_RESULT;

        const size_t string_length = (size_t)raw_length;
        if (string_length > length - position) return INVALID_RESULT;
        values[string_index].length = string_length;
        for (size_t digit = 0; digit < string_length; ++digit) {
            const int64_t raw_byte = input[position++];
            if (raw_byte < 0 || raw_byte > 255) return INVALID_RESULT;
            values[string_index].bytes[digit] = (uint8_t)raw_byte;
        }
    }
    if (position != length) return INVALID_RESULT;

    if (count > 1u) msd_sort(values, auxiliary, 0u, count, 0u);

    uint64_t hash = FNV_OFFSET_BASIS;
    hash = fnv1a_add(hash, (uint8_t)(count & 0xffu));
    hash = fnv1a_add(hash, (uint8_t)((count >> 8u) & 0xffu));
    for (size_t string_index = 0; string_index < count; ++string_index) {
        const EncodedString *value = &values[string_index];
        hash = fnv1a_add(hash, (uint8_t)value->length);
        for (size_t digit = 0; digit < value->length; ++digit)
            hash = fnv1a_add(hash, value->bytes[digit]);
    }
    return (int64_t)(hash & (uint64_t)INT64_MAX);
}
