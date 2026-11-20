#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 18, MAX_F = 12, MAX_DARTS = 36,
       MAX_INPUT = 55, MAX_OUTPUT = 128 };

typedef struct {
    int n, k, b, m, f, center, outer_id;
    int outer[MAX_N], degree[MAX_N], rotation[MAX_N][MAX_N], permutation[MAX_N];
    bool adjacent[MAX_N][MAX_N];
    int edge_u[MAX_M], edge_v[MAX_M];
    int face_len[MAX_F], face[MAX_F][MAX_N], dart_face[MAX_N][MAX_N];
} WedgeGraph;

static bool connected_without(const WedgeGraph *g, int removed_a, int removed_b)
{
    bool seen[MAX_N] = {false};
    int stack[MAX_N], top = 0, count = 0, expected = 0;
    int start = -1;
    for (int v = 0; v < g->n; ++v) {
        if (v == removed_a || v == removed_b) continue;
        ++expected;
        if (start < 0) start = v;
    }
    if (expected <= 1) return true;
    seen[start] = true; stack[top++] = start;
    while (top > 0) {
        const int u = stack[--top]; ++count;
        for (int v = 0; v < g->n; ++v) {
            if (v != removed_a && v != removed_b && g->adjacent[u][v] && !seen[v]) {
                seen[v] = true; stack[top++] = v;
            }
        }
    }
    return count == expected;
}

static int face_walk(const WedgeGraph *g, int first, int second, int cycle[MAX_DARTS])
{
    bool seen[MAX_N][MAX_N] = {{false}};
    const int start_u = first, start_v = second;
    int u = first, v = second, length = 0;
    for (int step = 0; step < 2 * g->m; ++step) {
        if (u < 0 || u >= g->n || v < 0 || v >= g->n || !g->adjacent[u][v] || seen[u][v])
            return -1;
        seen[u][v] = true;
        cycle[length++] = u;
        int at = -1;
        for (int i = 0; i < g->degree[v]; ++i)
            if (g->rotation[v][i] == u) { at = i; break; }
        if (at < 0) return -1;
        const int next = g->rotation[v][(at + 1) % g->degree[v]];
        u = v; v = next;
        if (u == start_u && v == start_v) return length;
    }
    return -1;
}

static bool same_cyclic(const int *a, const int *b, int length)
{
    for (int shift = 0; shift < length; ++shift) {
        bool equal = true;
        for (int i = 0; i < length; ++i)
            if (a[i] != b[(i + shift) % length]) { equal = false; break; }
        if (equal) return true;
    }
    return false;
}

static bool parse_graph(const int64_t *input, size_t length, WedgeGraph *g)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return false;
    if (input[0] < 4 || input[0] > MAX_N || input[1] < 3 || input[1] > MAX_N ||
        (input[0] - 1) % input[1] != 0 ||
        input[2] < input[1] || input[2] > input[0] || input[2] % input[1] != 0)
        return false;
    g->n = (int)input[0]; g->k = (int)input[1]; g->b = (int)input[2];
    size_t offset = 3;
    if (offset + (size_t)g->b > length) return false;
    bool outer_seen[MAX_N] = {false};
    for (int i = 0; i < g->b; ++i) {
        const int64_t raw = input[offset++];
        if (raw < 0 || raw >= g->n || outer_seen[raw]) return false;
        g->outer[i] = (int)raw; outer_seen[raw] = true;
    }
    int degree_sum = 0;
    for (int v = 0; v < g->n; ++v) {
        if (offset >= length) return false;
        const int64_t degree_raw = input[offset++];
        if (degree_raw < 3 || degree_raw >= g->n || offset + (size_t)degree_raw > length)
            return false;
        const int degree = (int)degree_raw;
        g->degree[v] = degree; degree_sum += degree;
        bool row_seen[MAX_N] = {false};
        for (int i = 0; i < degree; ++i) {
            const int64_t raw = input[offset++];
            if (raw < 0 || raw >= g->n || raw == v || row_seen[raw]) return false;
            const int neighbor = (int)raw;
            row_seen[neighbor] = true;
            g->rotation[v][i] = neighbor;
            g->adjacent[v][neighbor] = true;
        }
    }
    if (offset + (size_t)g->n != length || degree_sum % 2 != 0) return false;
    for (int v = 0; v < g->n; ++v) {
        const int64_t raw = input[offset++];
        if (raw < 0 || raw >= g->n) return false;
        g->permutation[v] = (int)raw;
    }
    bool permutation_seen[MAX_N] = {false};
    for (int v = 0; v < g->n; ++v) {
        if (permutation_seen[g->permutation[v]]) return false;
        permutation_seen[g->permutation[v]] = true;
    }
    g->m = degree_sum / 2;
    if (g->m < g->n || g->m > 3 * g->n - 6 || g->m > MAX_M) return false;
    for (int u = 0; u < g->n; ++u)
        for (int v = 0; v < g->n; ++v)
            if (g->adjacent[u][v] != g->adjacent[v][u]) return false;
    int edge_count = 0;
    for (int u = 0; u < g->n; ++u)
        for (int v = u + 1; v < g->n; ++v)
            if (g->adjacent[u][v]) { g->edge_u[edge_count] = u; g->edge_v[edge_count++] = v; }
    if (edge_count != g->m || !connected_without(g, -1, -1)) return false;
    for (int u = 0; u < g->n; ++u) {
        if (!connected_without(g, u, -1)) return false;
        for (int v = u + 1; v < g->n; ++v)
            if (!connected_without(g, u, v)) return false;
    }

    for (int u = 0; u < g->n; ++u)
        for (int v = 0; v < g->n; ++v) g->dart_face[u][v] = -1;
    g->f = 0;
    for (int e = 0; e < g->m; ++e) {
        const int ends[2][2] = {{g->edge_u[e], g->edge_v[e]}, {g->edge_v[e], g->edge_u[e]}};
        for (int d = 0; d < 2; ++d) {
            const int u = ends[d][0], v = ends[d][1];
            if (g->dart_face[u][v] >= 0) continue;
            if (g->f >= MAX_F) return false;
            int cycle[MAX_DARTS];
            const int face_length = face_walk(g, u, v, cycle);
            if (face_length < 3 || face_length > g->n) return false;
            bool face_seen[MAX_N] = {false};
            for (int i = 0; i < face_length; ++i) {
                const int a = cycle[i], b = cycle[(i + 1) % face_length];
                if (face_seen[a] || g->dart_face[a][b] >= 0) return false;
                face_seen[a] = true;
            }
            const int face_id = g->f++;
            g->face_len[face_id] = face_length;
            for (int i = 0; i < face_length; ++i) {
                const int a = cycle[i], b = cycle[(i + 1) % face_length];
                g->face[face_id][i] = a;
                g->dart_face[a][b] = face_id;
            }
        }
    }
    if (g->f != g->m - g->n + 2) return false;
    g->outer_id = -1;
    for (int face = 0; face < g->f; ++face)
        if (g->face_len[face] == g->b && same_cyclic(g->outer, g->face[face], g->b))
            g->outer_id = face;
    if (g->outer_id < 0) return false;

    int fixed_count = 0;
    for (int v = 0; v < g->n; ++v)
        if (g->permutation[v] == v) { g->center = v; ++fixed_count; }
    if (fixed_count != 1 || outer_seen[g->center]) return false;
    for (int v = 0; v < g->n; ++v) if (v != g->center) {
        int current = g->permutation[v], orbit_length = 1;
        while (current != v && orbit_length <= g->k) {
            current = g->permutation[current]; ++orbit_length;
        }
        if (current != v || orbit_length != g->k) return false;
    }
    int power[MAX_N];
    for (int v = 0; v < g->n; ++v) power[v] = v;
    for (int exponent = 1; exponent <= g->k; ++exponent) {
        int next[MAX_N], is_identity = 1;
        for (int v = 0; v < g->n; ++v) {
            next[v] = g->permutation[power[v]];
            if (next[v] != v) is_identity = 0;
        }
        for (int v = 0; v < g->n; ++v) power[v] = next[v];
        if (is_identity != (exponent == g->k)) return false;
    }
    for (int v = 0; v < g->n; ++v) {
        const int image = g->permutation[v];
        for (int w = 0; w < g->n; ++w)
            if (g->adjacent[v][w] != g->adjacent[image][g->permutation[w]]) return false;
        bool row_ok = false;
        for (int shift = 0; shift < g->degree[image] && !row_ok; ++shift) {
            bool equal = true;
            for (int i = 0; i < g->degree[v]; ++i)
                if (g->permutation[g->rotation[v][i]] !=
                    g->rotation[image][(i + shift) % g->degree[image]]) equal = false;
            if (equal) row_ok = true;
        }
        if (!row_ok) return false;
    }
    const int shift = g->b / g->k;
    for (int i = 0; i < g->b; ++i)
        if (g->permutation[g->outer[i]] != g->outer[(i + shift) % g->b]) return false;
    return true;
}

static int solve(const WedgeGraph *g, int64_t words[29])
{
    int distance[MAX_N];
    for (int v = 0; v < g->n; ++v) distance[v] = -1;
    int queue[MAX_N], head = 0, tail = 0;
    distance[g->center] = 0; queue[tail++] = g->center;
    while (head < tail) {
        const int u = queue[head++];
        for (int v = 0; v < g->n; ++v)
            if (g->adjacent[u][v] && distance[v] < 0) {
                distance[v] = distance[u] + 1; queue[tail++] = v;
            }
    }
    int endpoint = -1;
    for (int i = 0; i < g->b; ++i) {
        const int v = g->outer[i];
        if (endpoint < 0 || distance[v] < distance[endpoint] ||
            (distance[v] == distance[endpoint] && v < endpoint)) endpoint = v;
    }
    if (endpoint < 0 || distance[endpoint] <= 0) return -1;
    int to_endpoint[MAX_N];
    for (int v = 0; v < g->n; ++v) to_endpoint[v] = -1;
    head = tail = 0; to_endpoint[endpoint] = 0; queue[tail++] = endpoint;
    while (head < tail) {
        const int u = queue[head++];
        for (int v = 0; v < g->n; ++v)
            if (g->adjacent[u][v] && to_endpoint[v] < 0) {
                to_endpoint[v] = to_endpoint[u] + 1; queue[tail++] = v;
            }
    }
    int p1[MAX_N], p2[MAX_N], p0[MAX_N], p1_len = 1;
    p1[0] = g->center;
    while (p1[p1_len - 1] != endpoint && p1_len < MAX_N) {
        const int u = p1[p1_len - 1];
        int choice = -1;
        for (int v = 0; v < g->n; ++v)
            if (g->adjacent[u][v] && to_endpoint[v] == to_endpoint[u] - 1 &&
                (choice < 0 || v < choice)) choice = v;
        if (choice < 0) return -1;
        p1[p1_len++] = choice;
    }
    if (p1[p1_len - 1] != endpoint || p1_len - 1 != distance[endpoint]) return -1;
    int p2_len = p1_len;
    for (int i = 0; i < p1_len; ++i) p2[i] = g->permutation[p1[i]];
    const int endpoint2 = p2[p2_len - 1];
    if (endpoint2 == endpoint) return -1;
    for (int i = 1; i < p1_len - 1; ++i)
        for (int j = 1; j < p2_len; ++j)
            if (p1[i] == p2[j]) return -1;
    for (int i = 1; i < p1_len - 1; ++i)
        for (int j = 0; j < g->b; ++j) if (p1[i] == g->outer[j]) return -1;
    for (int i = 1; i < p2_len - 1; ++i)
        for (int j = 0; j < g->b; ++j) if (p2[i] == g->outer[j]) return -1;
    int start = -1;
    for (int i = 0; i < g->b; ++i) if (g->outer[i] == endpoint) start = i;
    if (start < 0) return -1;
    const int p0_len = g->b / g->k + 1;
    for (int i = 0; i < p0_len; ++i) p0[i] = g->outer[(start + i) % g->b];
    if (p0[p0_len - 1] != endpoint2) return -1;

    int cycle[3 * MAX_N], cycle_len = 0;
    for (int i = 0; i < p1_len; ++i) cycle[cycle_len++] = p1[i];
    for (int i = 1; i < p0_len; ++i) cycle[cycle_len++] = p0[i];
    for (int i = p2_len - 2; i >= 0; --i) cycle[cycle_len++] = p2[i];
    if (cycle[0] != g->center || cycle[cycle_len - 1] != g->center) return -1;
    bool cycle_vertex[MAX_N] = {false};
    bool cycle_edge[MAX_N][MAX_N] = {{false}};
    for (int i = 0; i + 1 < cycle_len; ++i) {
        const int u = cycle[i], v = cycle[i + 1];
        if (!g->adjacent[u][v] || cycle_vertex[u]) return -1;
        cycle_vertex[u] = true;
        cycle_edge[u][v] = cycle_edge[v][u] = true;
    }
    const int seed = g->dart_face[p0[1]][p0[0]];
    if (seed < 0 || seed == g->outer_id) return -1;

    bool dual[MAX_F][MAX_F] = {{false}}, in_wedge_face[MAX_F] = {false};
    for (int e = 0; e < g->m; ++e) {
        const int u = g->edge_u[e], v = g->edge_v[e];
        if (cycle_edge[u][v]) continue;
        const int left = g->dart_face[u][v], right = g->dart_face[v][u];
        dual[left][right] = dual[right][left] = true;
    }
    head = tail = 0; queue[tail++] = seed; in_wedge_face[seed] = true;
    while (head < tail) {
        const int face = queue[head++];
        for (int other = 0; other < g->f; ++other)
            if (dual[face][other] && !in_wedge_face[other]) {
                in_wedge_face[other] = true; queue[tail++] = other;
            }
    }
    if (in_wedge_face[g->outer_id]) return -1;
    bool in_wedge_vertex[MAX_N] = {false};
    for (int v = 0; v < g->n; ++v) in_wedge_vertex[v] = cycle_vertex[v];
    for (int f = 0; f < g->f; ++f)
        if (in_wedge_face[f])
            for (int i = 0; i < g->face_len[f]; ++i) in_wedge_vertex[g->face[f][i]] = true;
    int vertex_mask = 0, edge_mask = 0;
    for (int v = 0; v < g->n; ++v) if (in_wedge_vertex[v]) vertex_mask |= 1 << v;
    for (int e = 0; e < g->m; ++e)
        if (in_wedge_vertex[g->edge_u[e]] && in_wedge_vertex[g->edge_v[e]]) edge_mask |= 1 << e;
    int at = 0;
    words[at++] = p1_len; for (int i = 0; i < p1_len; ++i) words[at++] = p1[i];
    words[at++] = p2_len; for (int i = 0; i < p2_len; ++i) words[at++] = p2[i];
    words[at++] = p0_len; for (int i = 0; i < p0_len; ++i) words[at++] = p0[i];
    words[at++] = vertex_mask; words[at++] = edge_mask;
    return at;
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) output[offset + i] = (uint8_t)(bits >> (8 * i));
}

extern "C" int64_t symmetric_drawing_cyclic_wedge(const int64_t *input, size_t input_length,
                                                   uint8_t *output, size_t output_capacity)
{
    WedgeGraph graph = {0};
    if (!parse_graph(input, input_length, &graph)) return -1;
    int64_t words[29];
    const int word_count = solve(&graph, words);
    if (word_count < 0 || (size_t)word_count * 8 > MAX_OUTPUT) return -1;
    const size_t bytes = (size_t)word_count * 8;
    if (output == NULL || output_capacity < bytes) return -2;
    uint8_t temporary[MAX_OUTPUT];
    for (int i = 0; i < word_count; ++i) write_i64_le(temporary, (size_t)i * 8, words[i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = temporary[i];
    return (int64_t)bytes;
}
