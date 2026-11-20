/* Clean-room sample-induced compressed quadtree split profile. */
#include <stddef.h>
#include <stdint.h>

static void put_i64_le(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (unsigned b = 0; b < 8; ++b) out[at + b] = (uint8_t)(bits >> (8 * b));
}

int64_t k_quadtree_sampled_point_subdivision(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > 68) return -1;
    int64_t nv = input[0], kv = input[1], dv = input[2];
    if (nv < 1 || nv > 32 || kv < 1 || kv > nv || dv < 1 || dv > 8) return -1;
    size_t n = (size_t)nv, k = (size_t)kv, depth = (size_t)dv;
    if (length != 3 + 2*n) return -1;
    uint32_t keys[32];
    uint32_t side = 1u << depth;
    for (size_t i = 0; i < n; ++i) {
        int64_t x = input[3+2*i], y = input[4+2*i];
        if (x < 0 || y < 0 || (uint64_t)x >= side || (uint64_t)y >= side) return -1;
        uint32_t key = 0;
        for (int bit = (int)depth - 1; bit >= 0; --bit)
            key = (key << 2) | ((((uint32_t)x >> bit) & 1u) << 1) | (((uint32_t)y >> bit) & 1u);
        keys[i] = key;
    }
    for (size_t i = 1; i < n; ++i) {
        uint32_t value = keys[i];
        size_t j = i;
        while (j > 0 && keys[j-1] > value) { keys[j] = keys[j-1]; --j; }
        keys[j] = value;
    }
    for (size_t i = 1; i < n; ++i) if (keys[i] == keys[i-1]) return -1;
    size_t samples = (n - 1) / k + 1;
    uint8_t split_depth[31];
    uint32_t split_prefix[31];
    size_t split_count = 0;
    for (size_t i = 0; i + 1 < samples; ++i) {
        uint32_t a = keys[i*k], b = keys[(i+1)*k];
        size_t common = 0;
        while (common < depth) {
            size_t shift = 2 * (depth - common - 1);
            if (((a >> shift) & 3u) != ((b >> shift) & 3u)) break;
            ++common;
        }
        uint32_t prefix = common == 0 ? 0 : a >> (2 * (depth-common));
        size_t found = 0;
        while (found < split_count && (split_depth[found] != common || split_prefix[found] != prefix)) ++found;
        if (found == split_count) { split_depth[split_count] = (uint8_t)common; split_prefix[split_count++] = prefix; }
    }
    for (size_t i = 1; i < split_count; ++i) {
        uint8_t d = split_depth[i]; uint32_t p = split_prefix[i];
        uint32_t start = p << (2 * (depth-d));
        size_t j = i;
        while (j > 0) {
            uint8_t pd = split_depth[j-1]; uint32_t pp = split_prefix[j-1];
            uint32_t ps = pp << (2 * (depth-pd));
            if (ps < start || (ps == start && pd <= d)) break;
            split_depth[j] = pd; split_prefix[j] = pp; --j;
        }
        split_depth[j] = d; split_prefix[j] = p;
    }
    size_t words = 1 + 2*split_count, bytes = 8*words;
    if (output == NULL || capacity < bytes) return -2;
    put_i64_le(output, 0, (int64_t)split_count);
    for (size_t i = 0; i < split_count; ++i) {
        put_i64_le(output, 8*(1+2*i), split_depth[i]);
        put_i64_le(output, 8*(2+2*i), split_prefix[i]);
    }
    return (int64_t)bytes;
}
