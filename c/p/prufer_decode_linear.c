/* Uncompiled monotone-cursor Prüfer decoder draft. */
#include <stddef.h>
#include <stdint.h>
static void pdl_write(uint8_t *output, size_t offset, uint64_t value) {
    for (size_t i = 0; i < 8; ++i) output[offset+i] = (uint8_t)(value >> (8*i));
}
int64_t prufer_decode_linear(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 1 || length > 4096) return -1;
    int64_t nv = input[0];
    if (nv < 2 || nv > 4096 || length != (size_t)nv-1) return -1;
    size_t n = (size_t)nv;
    int count[4096] = {0};
    for (size_t i = 1; i < length; ++i) {
        if (input[i] < 0 || input[i] >= nv) return -1;
        ++count[(size_t)input[i]];
    }
    size_t needed = 16*(n-1);
    if (!output || capacity < needed) return -2;
    int cursor = (int)n-1;
    while (count[cursor] != 0) --cursor;
    int leaf = cursor;
    for (size_t i = 1; i < length; ++i) {
        int v = (int)input[i];
        pdl_write(output, 16*(i-1), (uint64_t)leaf);
        pdl_write(output, 16*(i-1)+8, (uint64_t)v);
        count[leaf] = -1;
        --count[v];
        if (count[v] == 0 && v > cursor) leaf = v;
        else { do { --cursor; } while (count[cursor] != 0); leaf = cursor; }
    }
    int other = 0;
    while (other == leaf || count[other] != 0) ++other;
    pdl_write(output, 16*(n-2), (uint64_t)leaf);
    pdl_write(output, 16*(n-2)+8, (uint64_t)other);
    return (int64_t)needed;
}
