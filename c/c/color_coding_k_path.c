/* Bounded colorful k-vertex path existence via subset/endpoint dynamic programming. */
#include <stddef.h>
#include <stdint.h>

int64_t color_coding_k_path(const int64_t *values, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (values == NULL) return -2;
    if (length < 3 || length > 147) return -1;
    int64_t nv = values[0], mv = values[1], kv = values[2];
    if (nv < 1 || nv > 12 || mv < 0 || mv > 66 || kv < 1 || kv > 6 || kv > nv) return -1;
    size_t n = (size_t)nv, m = (size_t)mv, k = (size_t)kv, split = 3 + (size_t)nv;
    if (length != split + 2 * m) return -1;
    size_t colors[12];
    uint16_t adjacency[12] = {0};
    for (size_t v = 0; v < n; ++v) {
        if (values[3 + v] < 0 || values[3 + v] >= (int64_t)k) return -1;
        colors[v] = (size_t)values[3 + v];
    }
    for (size_t e = 0; e < m; ++e) {
        int64_t av = values[split + 2*e], bv = values[split + 2*e + 1];
        if (av < 0 || bv < 0 || av >= nv || bv >= nv || av == bv) return -1;
        size_t a = (size_t)av, b = (size_t)bv;
        uint16_t ba = (uint16_t)(1u << b), bb = (uint16_t)(1u << a);
        if ((adjacency[a] & ba) != 0) return -1;
        adjacency[a] |= ba; adjacency[b] |= bb;
    }
    uint8_t dp[64][12] = {{0}};
    for (size_t v = 0; v < n; ++v) dp[1u << colors[v]][v] = 1;
    size_t full = (1u << k) - 1;
    int found = 0;
    for (size_t mask = 1; mask <= full && !found; ++mask) {
        for (size_t v = 0; v < n && !found; ++v) if (dp[mask][v]) {
            if (mask == full) { found = 1; break; }
            for (size_t u = 0; u < n; ++u)
                if ((adjacency[v] & (1u << u)) && !(mask & (1u << colors[u])))
                    dp[mask | (1u << colors[u])][u] = 1;
        }
    }
    if (output_capacity < 8 || output == NULL) return -2;
    int64_t answer = found;
    for (size_t i = 0; i < 8; ++i) output[i] = (uint8_t)(((uint64_t)answer >> (8*i)) & 255u);
    return 8;
}
