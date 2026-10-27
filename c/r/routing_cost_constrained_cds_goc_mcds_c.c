/* Clean-room bounded GOC-MCDS-C construction trace. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8 };

static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        out[at + byte] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t routing_cost_constrained_cds_goc_mcds_c(
        const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > 17 || input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + 2 * n) return -1;
    const uint64_t full = (UINT64_C(1) << n) - 1;
    uint64_t adjacency[MAX_N] = {0};
    int64_t ids[MAX_N] = {0};
    for (size_t v = 0; v < n; ++v) {
        const int64_t mask = input[1 + v];
        ids[v] = input[1 + n + v];
        if (mask < 0 || (uint64_t)mask > full || ((uint64_t)mask & (UINT64_C(1) << v)) != 0
                || ids[v] < 1 || ids[v] > 1000) return -1;
        adjacency[v] = (uint64_t)mask;
        for (size_t u = 0; u < v; ++u) if (ids[u] == ids[v]) return -1;
    }
    for (size_t u = 0; u < n; ++u)
        for (size_t v = 0; v < n; ++v)
            if (((adjacency[u] >> v) & 1u) != ((adjacency[v] >> u) & 1u)) return -1;
    uint64_t reached = 1;
    for (;;) {
        uint64_t expanded = reached;
        for (size_t v = 0; v < n; ++v) if ((reached >> v) & 1u) expanded |= adjacency[v];
        if (expanded == reached) break;
        reached = expanded;
    }
    if (reached != full) return -1;

    uint64_t white = full, independent = 0;
    while (white != 0) {
        uint64_t black = 0;
        for (size_t v = 0; v < n; ++v) {
            if (((white >> v) & 1u) == 0) continue;
            int has_lower_white_neighbor = 0;
            for (size_t u = 0; u < n; ++u)
                if (((white >> u) & 1u) && ((adjacency[v] >> u) & 1u) && ids[u] < ids[v])
                    has_lower_white_neighbor = 1;
            if (!has_lower_white_neighbor) black |= UINT64_C(1) << v;
        }
        if (black == 0) return -1;
        independent |= black;
        uint64_t removed = black;
        for (size_t v = 0; v < n; ++v) if ((black >> v) & 1u) removed |= adjacency[v];
        white &= ~removed;
    }

    size_t order[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        size_t j = i;
        order[i] = i;
        while (j > 0 && ids[order[j - 1]] > ids[order[j]]) {
            const size_t temp = order[j - 1]; order[j - 1] = order[j]; order[j] = temp; --j;
        }
    }
    uint64_t connectors = 0;
    for (size_t a = 0; a < n; ++a) {
        const size_t source = order[a];
        if (((independent >> source) & 1u) == 0) continue;
        for (size_t b = a + 1; b < n; ++b) {
            const size_t target = order[b];
            if (((independent >> target) & 1u) == 0) continue;
            int parent[MAX_N];
            size_t queue[MAX_N], head = 0, tail = 0;
            for (size_t v = 0; v < n; ++v) parent[v] = -2;
            parent[source] = -1; queue[tail++] = source;
            while (head < tail && parent[target] == -2) {
                const size_t current = queue[head++];
                for (size_t oi = 0; oi < n; ++oi) {
                    const size_t next = order[oi];
                    if (((adjacency[current] >> next) & 1u) && parent[next] == -2) {
                        parent[next] = (int)current; queue[tail++] = next;
                    }
                }
            }
            if (parent[target] == -2) return -1;
            size_t path[MAX_N], path_length = 0, current = target;
            while (current != source) {
                path[path_length++] = current;
                current = (size_t)parent[current];
            }
            path[path_length++] = source;
            if (path_length <= 4)
                for (size_t pi = 1; pi + 1 < path_length; ++pi) connectors |= UINT64_C(1) << path[pi];
        }
    }
    if (output == NULL || capacity < 16) return -2;
    uint8_t staged[16];
    put_i64(staged, 0, (int64_t)independent);
    put_i64(staged, 8, (int64_t)(independent | connectors));
    for (size_t i = 0; i < sizeof staged; ++i) output[i] = staged[i];
    return 16;
}
