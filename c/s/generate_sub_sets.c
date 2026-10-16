#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 12
#define MAX_SAFE INT64_C(9007199254740991)

static void put32(uint8_t *out, size_t *pos, uint32_t value)
{
    for (size_t i = 0; i < 4; ++i) { out[(*pos)++] = (uint8_t)value; value >>= 8; }
}

static void put64(uint8_t *out, size_t *pos, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) { out[(*pos)++] = (uint8_t)bits; bits >>= 8; }
}

int64_t generate_sub_sets(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > MAX_ITEMS + 1 || input[0] < 0 || input[0] > MAX_ITEMS) return -1;
    size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i) if (input[i + 1] < -MAX_SAFE || input[i + 1] > MAX_SAFE) return -1;
    size_t subsets = (size_t)1 << n;
    size_t total_items = n == 0 ? 0 : n * (subsets / 2);
    size_t needed = 4 + 4 * subsets + 8 * total_items;
    if (output == NULL || capacity < needed) return -2;
    size_t pos = 0;
    put32(output, &pos, (uint32_t)subsets);
    for (size_t mask = 0; mask < subsets; ++mask) {
        uint32_t count = 0;
        for (size_t j = 0; j < n; ++j) if (mask & ((size_t)1 << j)) ++count;
        put32(output, &pos, count);
        for (size_t j = 0; j < n; ++j) if (mask & ((size_t)1 << j)) put64(output, &pos, input[j + 1]);
    }
    return (int64_t)pos;
}
