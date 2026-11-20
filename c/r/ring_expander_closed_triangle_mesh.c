#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 12, MAX_T = 20, MAX_C = 60, MAX_INPUT = 64,
       MAX_OUTPUT = 504 };

static void put_i64_le(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (unsigned b = 0; b < 8; ++b) out[at + b] = (uint8_t)(bits >> (8u * b));
}

static int corner_vertex(const int64_t *faces, int corner) {
    return (int)faces[3 * (corner / 3) + corner % 3];
}

static int next_corner(int corner) { return 3 * (corner / 3) + (corner % 3 + 1) % 3; }
static int prev_corner(int corner) { return 3 * (corner / 3) + (corner % 3 + 2) % 3; }

static int run_ring(int n, int t, int seed, const int64_t *faces,
                    int64_t *trace, int *trace_count,
                    uint64_t *vertex_mask, uint64_t *triangle_mask) {
    int opposite[MAX_C];
    uint8_t link[MAX_N][MAX_N][MAX_N] = {{{0}}};
    uint8_t used[MAX_N] = {0};
    uint8_t edge_count[MAX_N][MAX_N] = {{0}};
    int32_t edge_first[MAX_N][MAX_N];
    int32_t edge_second[MAX_N][MAX_N];
    for (int c = 0; c < 3 * t; ++c) opposite[c] = -1;
    for (int a = 0; a < MAX_N; ++a)
        for (int b = 0; b < MAX_N; ++b) edge_first[a][b] = edge_second[a][b] = -1;

    for (int ti = 0; ti < t; ++ti) {
        int a = (int)faces[3 * ti], b = (int)faces[3 * ti + 1], c = (int)faces[3 * ti + 2];
        used[a] = used[b] = used[c] = 1;
        link[a][b][c] = link[a][c][b] = 1;
        link[b][c][a] = link[b][a][c] = 1;
        link[c][a][b] = link[c][b][a] = 1;
        for (int j = 0; j < 3; ++j) {
            int first = (int)faces[3 * ti + (j + 1) % 3];
            int second = (int)faces[3 * ti + (j + 2) % 3];
            int low = first < second ? first : second;
            int high = first < second ? second : first;
            uint8_t count = edge_count[low][high];
            if (count == 0) edge_first[low][high] = 3 * ti + j;
            else if (count == 1) edge_second[low][high] = 3 * ti + j;
            else return 0;
            edge_count[low][high] = (uint8_t)(count + 1);
        }
    }
    for (int v = 0; v < n; ++v) if (!used[v]) return 0;

    for (int low = 0; low < n; ++low) for (int high = low + 1; high < n; ++high) {
        if (edge_count[low][high] == 0) continue;
        if (edge_count[low][high] != 2) return 0;
        int a = edge_first[low][high], b = edge_second[low][high];
        int at = a / 3, aj = a % 3, bt = b / 3, bj = b % 3;
        int a0 = (int)faces[3 * at + (aj + 1) % 3], a1 = (int)faces[3 * at + (aj + 2) % 3];
        int b0 = (int)faces[3 * bt + (bj + 1) % 3], b1 = (int)faces[3 * bt + (bj + 2) % 3];
        if (a0 != b1 || a1 != b0) return 0;
        opposite[a] = b;
        opposite[b] = a;
    }

    for (int v = 0; v < n; ++v) {
        int start = -1;
        for (int w = 0; w < n; ++w) {
            int degree = 0;
            for (int x = 0; x < n; ++x) degree += link[v][w][x] != 0;
            if (degree && start < 0) start = w;
            if (degree && degree != 2) return 0;
        }
        if (start < 0) return 0;
        uint8_t seen[MAX_N] = {0};
        int queue[MAX_N], head = 0, tail = 0;
        seen[start] = 1; queue[tail++] = start;
        while (head < tail) {
            int w = queue[head++];
            for (int x = 0; x < n; ++x)
                if (link[v][w][x] && !seen[x]) { seen[x] = 1; queue[tail++] = x; }
        }
        for (int w = 0; w < n; ++w) {
            int degree = 0;
            for (int x = 0; x < n; ++x) degree += link[v][w][x] != 0;
            if (degree && !seen[w]) return 0;
        }
    }

    uint8_t reached[MAX_T] = {0};
    int queue[MAX_T], head = 0, tail = 0;
    reached[0] = 1; queue[tail++] = 0;
    while (head < tail) {
        int ti = queue[head++];
        for (int j = 0; j < 3; ++j) {
            int other = opposite[3 * ti + j] / 3;
            if (!reached[other]) { reached[other] = 1; queue[tail++] = other; }
        }
    }
    for (int ti = 0; ti < t; ++ti) if (!reached[ti]) return 0;

    uint8_t seen_corners[MAX_C] = {0};
    *vertex_mask = 0;
    *triangle_mask = 0;
    *trace_count = 0;
    *vertex_mask |= UINT64_C(1) << corner_vertex(faces, next_corner(seed));
    *vertex_mask |= UINT64_C(1) << corner_vertex(faces, prev_corner(seed));
    int stop = opposite[seed], current = seed;
    while (current != stop) {
        if (current < 0 || current >= 3 * t || seen_corners[current] || *trace_count >= 3 * t) return 0;
        seen_corners[current] = 1;
        trace[(*trace_count)++] = current;
        int ti = current / 3, vertex = corner_vertex(faces, current);
        if (((*vertex_mask >> vertex) & 1u) == 0) {
            *vertex_mask |= UINT64_C(1) << vertex;
            *triangle_mask |= UINT64_C(1) << ti;
        } else if (((*triangle_mask >> ti) & 1u) == 0) {
            current = opposite[current];
        }
        current = opposite[prev_corner(current)];
    }
    return 1;
}

int64_t ring_expander_closed_triangle_mesh(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 15 || length > MAX_INPUT) return -1;
    int64_t n64 = input[0], t64 = input[1], seed64 = input[2];
    if (n64 < 4 || n64 > MAX_N || t64 < 4 || t64 > MAX_T ||
        length != 3u + 3u * (size_t)t64 || seed64 < 0 || seed64 >= 3 * t64) return -1;
    int n = (int)n64, t = (int)t64, seed = (int)seed64;
    const int64_t *faces = input + 3;
    for (int i = 0; i < 3 * t; ++i) if (faces[i] < 0 || faces[i] >= n64) return -1;
    for (int ti = 0; ti < t; ++ti) {
        if (faces[3 * ti] == faces[3 * ti + 1] || faces[3 * ti + 1] == faces[3 * ti + 2] ||
            faces[3 * ti + 2] == faces[3 * ti]) return -1;
    }
    int64_t trace[MAX_C];
    int trace_count = 0;
    uint64_t vertices = 0, triangles = 0;
    if (!run_ring(n, t, seed, faces, trace, &trace_count, &vertices, &triangles)) return -1;
    size_t words = 1u + (size_t)trace_count + 2u;
    size_t bytes = 8u * words;
    if (output == NULL || capacity < bytes) return -2;
    put_i64_le(output, 0, trace_count);
    for (int i = 0; i < trace_count; ++i) put_i64_le(output, 8u * (size_t)(i + 1), trace[i]);
    put_i64_le(output, 8u * (size_t)(trace_count + 1), (int64_t)vertices);
    put_i64_le(output, 8u * (size_t)(trace_count + 2), (int64_t)triangles);
    return (int64_t)bytes;
}
