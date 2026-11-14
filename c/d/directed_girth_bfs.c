#include <stddef.h>
#include <stdint.h>

int64_t directed_girth_bfs(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > 131) return -1;
    if (input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 64) return -1;
    size_t n = (size_t)input[0], m = (size_t)input[1];
    if (length != 2 + 2*m) return -1;
    uint32_t outgoing[16] = {0};
    for (size_t i = 0; i < m; ++i) {
        int64_t u = input[2+2*i], v = input[3+2*i];
        if (u < 0 || v < 0 || u >= (int64_t)n || v >= (int64_t)n) return -1;
        outgoing[(size_t)u] |= UINT32_C(1) << (unsigned)v;
    }
    int best = 17;
    for (size_t start = 0; start < n; ++start) {
        int distance[16]; size_t queue[16], head = 0, tail = 0;
        for (size_t i = 0; i < n; ++i) distance[i] = -1;
        distance[start] = 0; queue[tail++] = start;
        while (head < tail) {
            size_t u = queue[head++];
            for (size_t v = 0; v < n; ++v) {
                if (!(outgoing[u] & (UINT32_C(1) << v))) continue;
                if (v == start) {
                    if (distance[u] + 1 < best) best = distance[u] + 1;
                } else if (distance[v] < 0) {
                    distance[v] = distance[u] + 1; queue[tail++] = v;
                }
            }
        }
    }
    return best == 17 ? 0 : best;
}
