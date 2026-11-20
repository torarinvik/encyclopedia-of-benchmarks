/* Uncompiled minimum tree path-partition draft. */
#include <stddef.h>
#include <stdint.h>
int64_t tree_minimum_path_partition(const int64_t *input, size_t length) {
    if (!input || length < 1 || length > 65) return -1;
    int64_t nv = input[0];
    if (nv < 1 || nv > 64 || length != (size_t)nv) return -1;
    size_t n = (size_t)nv;
    for (size_t v = 1; v < n; ++v)
        if (input[v] < 0 || input[v] >= (int64_t)v) return -1;
    int64_t base[64] = {0}, first[64] = {0}, second[64] = {0};
    for (size_t v = n; v-- > 1;) {
        size_t p = (size_t)input[v];
        int64_t best = base[v] + first[v] + second[v];
        int64_t gain = 1 + base[v] + first[v] - best;
        base[p] += best;
        if (gain > first[p]) { second[p] = first[p]; first[p] = gain; }
        else if (gain > second[p]) second[p] = gain;
    }
    return nv - base[0] - first[0] - second[0];
}
