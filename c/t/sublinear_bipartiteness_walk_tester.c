#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_D = 4, MAX_EDGES = 32, MAX_T = 4, MAX_R = 8, MAX_L = 8, MAX_INPUT = 330 };

static void put_i64(uint8_t *out, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) { out[i] = (uint8_t)bits; bits >>= 8; }
}

int64_t sublinear_bipartiteness_walk_tester(const int64_t *values, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (!values || length < 8 || length > MAX_INPUT || values[0] < 1 || values[0] > MAX_N ||
        values[1] < 3 || values[1] > MAX_D || values[2] < 0 || values[2] > MAX_EDGES) return -1;
    const int n = (int)values[0], d = (int)values[1], m = (int)values[2];
    if (m > n * d / 2) return -1;
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    int neighbors[MAX_N][MAX_D] = {{0}}, degree[MAX_N] = {0};
    size_t suffix = (size_t)(3 + 2 * m);
    if (length < suffix + 4 || values[suffix] < 1 || values[suffix] > MAX_T ||
        values[suffix + 1] < 1 || values[suffix + 1] > MAX_R ||
        values[suffix + 2] < 1 || values[suffix + 2] > MAX_L) return -1;
    const int starts_count = (int)values[suffix], walks = (int)values[suffix + 1], steps = (int)values[suffix + 2];
    const size_t expected = suffix + 3 + (size_t)starts_count + (size_t)starts_count * walks * steps;
    if (length != expected) return -1;
    for (int edge = 0; edge < m; ++edge) {
        const int64_t a0 = values[3 + 2 * edge], b0 = values[4 + 2 * edge];
        if (a0 < 0 || b0 < 0 || a0 >= n || b0 >= n || a0 >= b0) return -1;
        const int a = (int)a0, b = (int)b0;
        if (adjacent[a][b] || degree[a] >= d || degree[b] >= d) return -1;
        adjacent[a][b] = adjacent[b][a] = 1;
        int at = degree[a]++;
        while (at > 0 && neighbors[a][at - 1] > b) { neighbors[a][at] = neighbors[a][at - 1]; --at; }
        neighbors[a][at] = b;
        at = degree[b]++;
        while (at > 0 && neighbors[b][at - 1] > a) { neighbors[b][at] = neighbors[b][at - 1]; --at; }
        neighbors[b][at] = a;
    }
    const size_t starts_at = suffix + 3, draws_at = starts_at + (size_t)starts_count;
    for (int t = 0; t < starts_count; ++t) if (values[starts_at + (size_t)t] < 0 || values[starts_at + (size_t)t] >= n) return -1;
    const size_t draw_count = (size_t)starts_count * walks * steps;
    for (size_t i = 0; i < draw_count; ++i) if (values[draws_at + i] < 0 || values[draws_at + i] >= 2 * d) return -1;

    int accepted = 1;
    size_t draw = 0;
    for (int t = 0; t < starts_count && accepted; ++t) {
        uint8_t parity_seen[MAX_N] = {0};
        const int start = (int)values[starts_at + (size_t)t];
        for (int walk = 0; walk < walks && accepted; ++walk) {
            int vertex = start, parity = 0;
            parity_seen[vertex] |= 1u;
            for (int step = 0; step < steps; ++step) {
                const int choice = (int)values[draws_at + draw++];
                if (choice < degree[vertex]) { vertex = neighbors[vertex][choice]; parity ^= 1; }
                parity_seen[vertex] |= (uint8_t)(1u << parity);
                if (parity_seen[vertex] == 3u) { accepted = 0; break; }
            }
        }
    }
    if (!output || capacity < 8) return -2;
    uint8_t staged[8]; put_i64(staged, accepted);
    for (size_t i = 0; i < 8; ++i) output[i] = staged[i];
    return 8;
}
