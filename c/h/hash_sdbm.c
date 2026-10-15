/* Hash ASCII byte arrays with the pinned 64-bit SDBM recurrence. */
#include <stddef.h>
#include <stdint.h>

#define MAX_BYTES 64

static int64_t signed_bits(uint64_t value)
{
    if (value <= INT64_MAX) return (int64_t)value;
    return INT64_MIN + (int64_t)(value - (UINT64_C(1) << 63));
}

int64_t hash_sdbm(const int64_t *input, size_t length)
{
    if (length == 0 || length > MAX_BYTES || input == NULL) return -1;
    uint64_t hash = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t byte = input[index];
        if (byte < 1 || byte > 127) return -1;
        hash = (uint64_t)byte + (hash << 6) + (hash << 16) - hash;
    }
    return signed_bits(hash);
}
