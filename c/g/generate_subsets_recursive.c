#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 12

static void put32(uint8_t *out, size_t *pos, uint32_t value)
{
    for (size_t i = 0; i < 4; ++i) { out[(*pos)++] = (uint8_t)value; value >>= 8; }
}

static void emit_subsets(const int64_t *input, size_t n, size_t index,
                         uint32_t mask, uint32_t selected, uint8_t *output, size_t *pos)
{
    if (index == n) {
        put32(output, pos, selected);
        for (size_t i = 0; i < n; ++i)
            if ((mask & (UINT32_C(1) << i)) != 0) output[(*pos)++] = (uint8_t)input[i + 1];
        return;
    }
    emit_subsets(input, n, index + 1, mask | (UINT32_C(1) << index), selected + 1, output, pos);
    emit_subsets(input, n, index + 1, mask, selected, output, pos);
}

int64_t generate_subsets_recursive(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > MAX_ITEMS + 1 || input[0] < 0 || input[0] > MAX_ITEMS) return -1;
    size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 127) return -1;
    size_t subsets = (size_t)1 << n;
    size_t needed = 4 + 4 * subsets + n * (subsets / 2);
    if (output == NULL || capacity < needed) return -2;
    size_t pos = 0;
    put32(output, &pos, (uint32_t)subsets);
    emit_subsets(input, n, 0, 0, 0, output, &pos);
    return (int64_t)pos;
}
