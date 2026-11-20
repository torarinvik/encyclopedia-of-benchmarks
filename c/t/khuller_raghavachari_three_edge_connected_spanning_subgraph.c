#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define KR_MAX_N 8
#define KR_MAX_M 28
#define KR_MAX_INPUT 59

static void kr_put(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        out[at + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t khuller_raghavachari_three_edge_connected_spanning_subgraph(
        const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > KR_MAX_INPUT) return -1;
    int64_t n64 = input[0], m64 = input[1];
    if (n64 < 4 || n64 > KR_MAX_N || m64 < 6 || m64 > KR_MAX_M
            || length != 2 + 2 * (size_t)m64) return -1;
    size_t n = (size_t)n64, m = (size_t)m64;
    size_t u[KR_MAX_M], v[KR_MAX_M];
    for (size_t e = 0; e < m; ++e) {
        int64_t a = input[2 + 2 * e], b = input[3 + 2 * e];
        if (a < 0 || a >= b || b >= n64) return -1;
        u[e] = (size_t)a; v[e] = (size_t)b;
        for (size_t prior = 0; prior < e; ++prior)
            if (u[prior] == u[e] && v[prior] == v[e]) return -1;
    }
    size_t full = ((size_t)1 << n) - 1;
    for (size_t side = 1; side < full; ++side) {
        if ((side & 1U) == 0) continue;
        size_t cut_size = 0;
        for (size_t e = 0; e < m; ++e)
            if (((side >> u[e]) & 1U) != ((side >> v[e]) & 1U)) ++cut_size;
        if (cut_size < 3) return -1;
    }

    bool selected[KR_MAX_M] = {false};
    size_t state[KR_MAX_N] = {0}, discovery[KR_MAX_N] = {0}, finish[KR_MAX_N] = {0};
    size_t parent[KR_MAX_N] = {0}, parent_edge[KR_MAX_N] = {0};
    size_t postorder[KR_MAX_N] = {0}, post_count = 0;
    size_t stack_vertex[KR_MAX_N] = {0}, stack_slot[KR_MAX_N] = {0};
    size_t clock = 1, top = 1;
    state[0] = 1; discovery[0] = 0; parent[0] = n; parent_edge[0] = m;
    stack_vertex[0] = 0;
    while (top > 0) {
        size_t frame = top - 1, x = stack_vertex[frame];
        if (stack_slot[frame] < m) {
            size_t e = stack_slot[frame]++;
            size_t y = n;
            if (u[e] == x) y = v[e]; else if (v[e] == x) y = u[e];
            if (y == n || state[y] != 0) continue;
            selected[e] = true; state[y] = 1; parent[y] = x; parent_edge[y] = e;
            discovery[y] = clock++;
            stack_vertex[top] = y; stack_slot[top] = 0; ++top;
            continue;
        }
        state[x] = 2;
        finish[x] = clock;
        if (parent_edge[x] < m) postorder[post_count++] = parent_edge[x];
        --top;
    }

    for (size_t p = 0; p < post_count; ++p) {
        size_t tree_edge = postorder[p];
        size_t child = parent_edge[u[tree_edge]] == tree_edge ? u[tree_edge] : v[tree_edge];
        size_t upper = parent[child];
        bool has_one_edge_cut = false;
        for (size_t removed = 0; removed < m && !has_one_edge_cut; ++removed) {
            if (!selected[removed]) continue;
            bool seen[KR_MAX_N] = {false};
            size_t queue[KR_MAX_N], head = 0, tail = 1;
            seen[upper] = true; queue[0] = upper;
            while (head < tail) {
                size_t current = queue[head++];
                for (size_t e = 0; e < m; ++e) {
                    if (!selected[e] || e == removed) continue;
                    size_t next = u[e] == current ? v[e] : v[e] == current ? u[e] : n;
                    if (next < n && !seen[next]) { seen[next] = true; queue[tail++] = next; }
                }
            }
            has_one_edge_cut = !seen[child];
        }
        if (!has_one_edge_cut) continue;
        size_t candidate = m, earliest = n;
        for (size_t e = 0; e < m; ++e) {
            if (selected[e]) continue;
            bool u_inside = discovery[child] <= discovery[u[e]] && discovery[u[e]] < finish[child];
            bool v_inside = discovery[child] <= discovery[v[e]] && discovery[v[e]] < finish[child];
            if (u_inside == v_inside) continue;
            size_t ancestor = u_inside ? v[e] : u[e];
            if (discovery[ancestor] < earliest) { earliest = discovery[ancestor]; candidate = e; }
        }
        if (candidate == m) return -1;
        selected[candidate] = true;
    }

    size_t leader[KR_MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) leader[vertex] = vertex;
    for (size_t e = 0; e < m; ++e) {
        if (selected[e]) continue;
        size_t a = u[e], b = v[e];
        while (leader[a] != a) { leader[a] = leader[leader[a]]; a = leader[a]; }
        while (leader[b] != b) { leader[b] = leader[leader[b]]; b = leader[b]; }
        if (a != b) { leader[b] = a; selected[e] = true; }
    }
    size_t count = 0;
    for (size_t e = 0; e < m; ++e) if (selected[e]) ++count;
    size_t bytes = 8 * (1 + 2 * count);
    if (output == NULL || capacity < bytes) return -2;
    kr_put(output, 0, (int64_t)count);
    size_t slot = 0;
    for (size_t e = 0; e < m; ++e) if (selected[e]) {
        kr_put(output, 8 * (1 + 2 * slot), (int64_t)u[e]);
        kr_put(output, 8 * (2 + 2 * slot), (int64_t)v[e]);
        ++slot;
    }
    return (int64_t)bytes;
}
