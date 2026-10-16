/* Hash a bounded ASCII codepoint array with the Python ELF recurrence. */
#include <stddef.h>
#include <stdint.h>

#define MAX_CODEPOINTS 8

int64_t elf_hash(const int64_t *input, size_t length)
{
    if (length > MAX_CODEPOINTS || (input == NULL && length != 0)) return -1;

    uint64_t hash = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t codepoint = input[index];
        if (codepoint < 0 || codepoint > 127) return -1;

        hash = (hash << 4) + (uint64_t)codepoint;
        const uint64_t high = hash & UINT64_C(0xF0000000);
        if (high != 0) hash ^= high >> 24;
        hash ^= high;
    }
    return (int64_t)hash;
}
