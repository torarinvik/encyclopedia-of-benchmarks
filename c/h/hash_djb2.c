#include <stddef.h>
#include <stdint.h>

#define MAX_BYTES 3

int64_t hash_djb2(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_BYTES + 1) return -1;
    const int64_t count_value = input[0];
    if (count_value < 0 || count_value > MAX_BYTES || length != (size_t)count_value + 1) return -1;
    uint64_t hash = 5381;
    for (size_t index = 0; index < (size_t)count_value; ++index) {
        const int64_t byte = input[index + 1];
        if (byte < 1 || byte > 127) return -1;
        hash = hash * 33 + (uint64_t)byte;
    }
    return (int64_t)hash;
}
