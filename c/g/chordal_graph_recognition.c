#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

enum { MAX_N = 6, MAX_M = 15, MAX_INPUT = 32, MAX_OUTPUT_VALUES = 8, MAX_OUTPUT_BYTES = 64 };

static void put_u64(uint8_t *out, size_t index, uint64_t value) {
    for (size_t byte = 0; byte < 8; ++byte) out[index * 8 + byte] = (uint8_t)(value >> (8 * byte));
}

static int has_induced_cycle(const bool adjacent[MAX_N][MAX_N], int n, int *cycle, int *cycle_length) {
    const unsigned limit = 1u << n;
    for (unsigned mask = 0; mask < limit; ++mask) {
        int vertices[MAX_N], count = 0;
        for (int v = 0; v < n; ++v) if (mask & (1u << v)) vertices[count++] = v;
        if (count < 4) continue;
        int degree[MAX_N] = {0};
        for (int i = 0; i < count; ++i)
            for (int j = 0; j < count; ++j) degree[vertices[i]] += adjacent[vertices[i]][vertices[j]];
        int degrees_ok = 1;
        for (int i = 0; i < count; ++i) if (degree[vertices[i]] != 2) degrees_ok = 0;
        if (!degrees_ok) continue;
        int seen[MAX_N] = {0}, queue[MAX_N], head = 0, tail = 0;
        seen[vertices[0]] = 1; queue[tail++] = vertices[0];
        while (head < tail) {
            const int v = queue[head++];
            for (int i = 0; i < count; ++i) {
                const int u = vertices[i];
                if (adjacent[v][u] && !seen[u]) { seen[u] = 1; queue[tail++] = u; }
            }
        }
        if (tail != count) continue;
        const int start = vertices[0];
        int previous = -1, current = -1;
        for (int i = 0; i < count; ++i) if (adjacent[start][vertices[i]]) { current = vertices[i]; break; }
        for (int i = 0; i < count; ++i) {
            cycle[i] = i == 0 ? start : current;
            if (i == 0) { previous = start; continue; }
            const int here = current;
            int next = -1;
            for (int j = 0; j < count; ++j)
                if (adjacent[here][vertices[j]] && vertices[j] != previous) { next = vertices[j]; break; }
            previous = here;
            current = next;
        }
        *cycle_length = count;
        return 1;
    }
    return 0;
}

int64_t chordal_graph_recognition(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > MAX_INPUT || input[0] < 1 || input[0] > MAX_N ||
        input[1] < 0 || input[1] > MAX_M) return -1;
    const int n = (int)input[0], m = (int)input[1];
    if (m > n * (n - 1) / 2 || length != (size_t)(2 + 2 * m)) return -1;
    bool adjacent[MAX_N][MAX_N] = {{false}};
    for (int edge = 0; edge < m; ++edge) {
        const int64_t a0 = input[2 + 2 * edge], b0 = input[3 + 2 * edge];
        if (a0 < 0 || b0 < 0 || a0 >= n || b0 >= n || a0 == b0) return -1;
        const int a = (int)a0, b = (int)b0;
        if (adjacent[a][b]) return -1;
        adjacent[a][b] = adjacent[b][a] = true;
    }
    int selected[MAX_N] = {0}, label[MAX_N] = {0}, reverse_order[MAX_N], order[MAX_N];
    for (int step = 0; step < n; ++step) {
        int chosen = -1;
        for (int v = 0; v < n; ++v)
            if (!selected[v] && (chosen < 0 || label[v] > label[chosen])) chosen = v;
        selected[chosen] = 1;
        reverse_order[step] = chosen;
        for (int u = 0; u < n; ++u) if (!selected[u] && adjacent[chosen][u]) ++label[u];
    }
    for (int i = 0; i < n; ++i) order[i] = reverse_order[n - i - 1];
    int position[MAX_N];
    for (int i = 0; i < n; ++i) position[order[i]] = i;
    int is_peo = 1;
    for (int i = 0; i < n && is_peo; ++i) {
        const int v = order[i];
        int parent = -1;
        for (int u = 0; u < n; ++u)
            if (adjacent[v][u] && position[u] > i && (parent < 0 || position[u] < position[parent])) parent = u;
        if (parent >= 0) for (int u = 0; u < n; ++u)
            if (adjacent[v][u] && position[u] > i && u != parent && !adjacent[parent][u]) is_peo = 0;
    }
    uint64_t packed[MAX_OUTPUT_VALUES];
    size_t count = 0;
    if (is_peo) {
        packed[count++] = 1;
        for (int i = 0; i < n; ++i) packed[count++] = (uint64_t)order[i];
    } else {
        int cycle[MAX_N], cycle_length = 0;
        if (!has_induced_cycle(adjacent, n, cycle, &cycle_length)) return -1;
        packed[count++] = 0;
        packed[count++] = (uint64_t)cycle_length;
        for (int i = 0; i < cycle_length; ++i) packed[count++] = (uint64_t)cycle[i];
    }
    const size_t bytes = count * 8;
    if (!output || capacity < bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES];
    for (size_t i = 0; i < count; ++i) put_u64(staged, i, packed[i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
