#include <stddef.h>
#include <stdint.h>

#define MAX_WORD_BYTES 64
#define MAX_TABLE_SIZE INT64_C(2147483647)

static uint32_t upper_ascii(uint32_t c) {
    return c >= (uint32_t)'a' && c <= (uint32_t)'z' ? c - 32u : c;
}

int64_t cbench_ispell_hash(const int64_t *values, size_t length) {
    if (values == NULL || length == 0 || length > MAX_WORD_BYTES + 1) return -1;
    int64_t table_size = values[0];
    if (table_size < 1 || table_size > MAX_TABLE_SIZE) return -1;
    uint32_t h = 0;
    size_t count = length - 1;
    for (size_t i = 0; i < count; ++i)
        if (values[i + 1] < 1 || values[i + 1] > 127) return -1;
    size_t initial = count < 4 ? count : 4;
    for (size_t i = 0; i < initial; ++i)
        h = (h << 8) | upper_ascii((uint32_t)values[i + 1]);
    for (size_t i = initial; i < count; ++i) {
        h = (h << 5) | (h >> 27);
        h ^= upper_ascii((uint32_t)values[i + 1]);
    }
    return (int64_t)((uint64_t)h % (uint64_t)table_size);
}
