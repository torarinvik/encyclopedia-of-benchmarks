#include <stddef.h>
#include <stdint.h>

static size_t srm_root(size_t *parent, size_t x) {
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
}

int64_t statistical_region_merging_table(const int64_t *input, size_t length,
                                          uint8_t *output, size_t capacity) {
    if (!input || length < 4 || length > 74 || input[0] < 1 || input[0] > 6 ||
        input[1] < 1 || input[1] > 6) return -1;
    const size_t width = (size_t)input[1], n = (size_t)input[0] * width;
    if (length != 2 + 2*n) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[2+i] < 0 || input[2+i] > 65535 || input[2+n+i] < 0 || input[2+n+i] > 255) return -1;
    size_t parent[36], sizes[36], minimum[36];
    int64_t sums[36];
    for (size_t i = 0; i < n; ++i) { parent[i] = minimum[i] = i; sizes[i] = 1; sums[i] = input[2+n+i]; }
    for (int difference = 0; difference < 256; ++difference) {
        for (size_t p = 0; p < n; ++p) {
            size_t neighbors[2], count = 0;
            if (p % width + 1 < width) neighbors[count++] = p + 1;
            if (p + width < n) neighbors[count++] = p + width;
            for (size_t k = 0; k < count; ++k) {
                size_t q = neighbors[k];
                int64_t d = input[2+n+p] - input[2+n+q];
                if (d < 0) d = -d;
                if (d != difference) continue;
                size_t a = srm_root(parent, p), b = srm_root(parent, q);
                if (a == b) continue;
                int64_t na = (int64_t)sizes[a], nb = (int64_t)sizes[b];
                int64_t delta = sums[a]*nb - sums[b]*na;
                int64_t bound = input[2+sizes[a]-1] + input[2+sizes[b]-1];
                if (delta*delta > bound*na*na*nb*nb) continue;
                if (sizes[a] < sizes[b]) { size_t t = a; a = b; b = t; }
                parent[b] = a;
                sizes[a] += sizes[b]; sums[a] += sums[b];
                if (minimum[b] < minimum[a]) minimum[a] = minimum[b];
            }
        }
    }
    if (!output || capacity < n) return -2;
    for (size_t i = 0; i < n; ++i) output[i] = (uint8_t)minimum[srm_root(parent, i)];
    return (int64_t)n;
}
