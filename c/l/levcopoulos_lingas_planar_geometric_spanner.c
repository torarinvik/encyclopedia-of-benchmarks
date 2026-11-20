#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum {
    MAX_N = 8,
    MAX_EDGES = 18,
    MAX_FACES = 16,
    MAX_DARTS = 2 * (MAX_N - 1),
    MAX_STACK = 64,
    MAX_INPUT = 55,
    MAX_OUTPUT_BYTES = 312
};

typedef struct {
    int64_t x[MAX_N];
    int64_t y[MAX_N];
    int64_t edge_u[MAX_EDGES];
    int64_t edge_v[MAX_EDGES];
    size_t edge_count;
    int64_t face_a[MAX_FACES];
    int64_t face_b[MAX_FACES];
    int64_t face_c[MAX_FACES];
    size_t face_count;
    int64_t rotation[MAX_N][MAX_N];
    size_t degree[MAX_N];
    int64_t tree_rotation[MAX_N][MAX_N];
    size_t tree_degree[MAX_N];
    int64_t contour_u[MAX_DARTS];
    int64_t contour_v[MAX_DARTS];
    size_t contour_length;
    int64_t stack_u[MAX_STACK];
    int64_t stack_v[MAX_STACK];
    size_t stack_size;
    double weight[MAX_N][MAX_N];
    uint8_t hull[MAX_N];
    uint8_t tree[MAX_N][MAX_N];
    uint8_t kept[MAX_N][MAX_N];
} State;

static int64_t orient(const State *s, int64_t a, int64_t b, int64_t c) {
    return (s->x[b] - s->x[a]) * (s->y[c] - s->y[a])
         - (s->y[b] - s->y[a]) * (s->x[c] - s->x[a]);
}

static int64_t incircle_det(const State *s, int64_t a, int64_t b,
                            int64_t c, int64_t p) {
    const int64_t ax = s->x[a] - s->x[p], ay = s->y[a] - s->y[p];
    const int64_t bx = s->x[b] - s->x[p], by = s->y[b] - s->y[p];
    const int64_t cx = s->x[c] - s->x[p], cy = s->y[c] - s->y[p];
    return (ax * ax + ay * ay) * (bx * cy - by * cx)
         - (bx * bx + by * by) * (ax * cy - ay * cx)
         + (cx * cx + cy * cy) * (ax * by - ay * bx);
}

static int64_t distance_squared(const State *s, int64_t a, int64_t b) {
    const int64_t dx = s->x[a] - s->x[b], dy = s->y[a] - s->y[b];
    return dx * dx + dy * dy;
}

static void sort_three(int64_t *a, int64_t *b, int64_t *c) {
    int64_t t;
    if (*a > *b) { t = *a; *a = *b; *b = t; }
    if (*b > *c) { t = *b; *b = *c; *c = t; }
    if (*a > *b) { t = *a; *a = *b; *b = t; }
}

static int is_face(const State *s, int64_t a, int64_t b, int64_t c) {
    sort_three(&a, &b, &c);
    for (size_t i = 0; i < s->face_count; ++i)
        if (s->face_a[i] == a && s->face_b[i] == b && s->face_c[i] == c) return 1;
    return 0;
}

static int angle_less(const State *s, int64_t origin, int64_t a, int64_t b) {
    const int64_t ax = s->x[a] - s->x[origin], ay = s->y[a] - s->y[origin];
    const int64_t bx = s->x[b] - s->x[origin], by = s->y[b] - s->y[origin];
    const int ah = (ay > 0 || (ay == 0 && ax >= 0)) ? 0 : 1;
    const int bh = (by > 0 || (by == 0 && bx >= 0)) ? 0 : 1;
    if (ah != bh) return ah < bh;
    const int64_t cross = ax * by - ay * bx;
    if (cross != 0) return cross > 0;
    return a < b;
}

static int add_rotation_neighbor(State *s, int64_t a, int64_t b) {
    if (s->degree[a] >= MAX_N || s->degree[b] >= MAX_N) return 0;
    s->rotation[a][s->degree[a]++] = b;
    s->rotation[b][s->degree[b]++] = a;
    return 1;
}

static void sort_rotations(State *s) {
    for (int64_t v = 0; v < MAX_N; ++v) {
        for (size_t i = 1; i < s->degree[v]; ++i) {
            const int64_t key = s->rotation[v][i];
            size_t pos = i;
            while (pos > 0 && angle_less(s, v, key, s->rotation[v][pos - 1])) {
                s->rotation[v][pos] = s->rotation[v][pos - 1];
                --pos;
            }
            s->rotation[v][pos] = key;
        }
    }
}

static int cw_next(const State *s, int64_t u, int64_t v,
                   int64_t *next_u, int64_t *next_v) {
    for (size_t i = 0; i < s->degree[v]; ++i) {
        if (s->rotation[v][i] == u) {
            *next_u = v;
            *next_v = s->rotation[v][(i + s->degree[v] - 1) % s->degree[v]];
            return 1;
        }
    }
    return 0;
}

static int cw_tree_next(const State *s, int64_t u, int64_t v,
                        int64_t *next_u, int64_t *next_v) {
    for (size_t i = 0; i < s->tree_degree[v]; ++i) {
        if (s->tree_rotation[v][i] == u) {
            *next_u = v;
            *next_v = s->tree_rotation[v][(i + s->tree_degree[v] - 1) % s->tree_degree[v]];
            return 1;
        }
    }
    return 0;
}

static int contour_find(const State *s, int64_t u, int64_t v) {
    for (size_t i = 0; i < s->contour_length; ++i)
        if (s->contour_u[i] == u && s->contour_v[i] == v) return (int)i;
    return -1;
}

static void canonicalize_contour(State *s) {
    if (s->contour_length == 0) return;
    size_t first = 0;
    for (size_t i = 1; i < s->contour_length; ++i)
        if (s->contour_u[i] < s->contour_u[first] ||
            (s->contour_u[i] == s->contour_u[first] && s->contour_v[i] < s->contour_v[first]))
            first = i;
    if (first == 0) return;
    int64_t temp_u[MAX_DARTS], temp_v[MAX_DARTS];
    for (size_t i = 0; i < s->contour_length; ++i) {
        const size_t at = (first + i) % s->contour_length;
        temp_u[i] = s->contour_u[at];
        temp_v[i] = s->contour_v[at];
    }
    for (size_t i = 0; i < s->contour_length; ++i) {
        s->contour_u[i] = temp_u[i];
        s->contour_v[i] = temp_v[i];
    }
}

static int eligible(const State *s, int64_t u, int64_t v) {
    const int at = contour_find(s, u, v);
    if (at < 0 || s->hull[v] || s->contour_length < 3) return 0;
    const size_t next = ((size_t)at + 1) % s->contour_length;
    int64_t cw_u, cw_v;
    return cw_next(s, u, v, &cw_u, &cw_v)
        && s->contour_u[next] == cw_u && s->contour_v[next] == cw_v
        && is_face(s, u, v, cw_v);
}

static int push_candidate(State *s, int64_t u, int64_t v) {
    if (!eligible(s, u, v)) return 1;
    if (s->stack_size >= MAX_STACK) return 0;
    s->stack_u[s->stack_size] = u;
    s->stack_v[s->stack_size] = v;
    ++s->stack_size;
    return 1;
}

static int validate_and_parse(State *s, const int64_t *input, size_t length,
                              size_t *n_out) {
    if (input == NULL || length < 14 || length > MAX_INPUT) return 0;
    const int64_t n64 = input[0];
    if (n64 < 3 || n64 > MAX_N) return 0;
    const size_t n = (size_t)n64;
    const size_t m_at = 1 + 2 * n;
    if (length <= m_at) return 0;
    const int64_t m64 = input[m_at];
    if (m64 < 3 || m64 > MAX_EDGES || length != m_at + 1 + 2 * (size_t)m64) return 0;
    const size_t m = (size_t)m64;
    for (size_t i = 0; i < n; ++i) {
        s->x[i] = input[1 + 2 * i];
        s->y[i] = input[2 + 2 * i];
        if (s->x[i] < -10 || s->x[i] > 10 || s->y[i] < -10 || s->y[i] > 10) return 0;
        for (size_t j = 0; j < i; ++j)
            if (s->x[i] == s->x[j] && s->y[i] == s->y[j]) return 0;
    }
    for (int64_t a = 0; a < n64; ++a)
        for (int64_t b = a + 1; b < n64; ++b)
            for (int64_t c = b + 1; c < n64; ++c)
                if (orient(s, a, b, c) == 0) return 0;
    for (int64_t a = 0; a < n64; ++a)
        for (int64_t b = a + 1; b < n64; ++b)
            for (int64_t c = b + 1; c < n64; ++c)
                for (int64_t d = c + 1; d < n64; ++d)
                    if (incircle_det(s, a, b, c, d) == 0) return 0;

    s->edge_count = m;
    uint8_t supplied[MAX_N][MAX_N] = {{0}};
    for (size_t i = 0; i < m; ++i) {
        const int64_t u = input[m_at + 1 + 2 * i];
        const int64_t v = input[m_at + 2 + 2 * i];
        if (u < 0 || v <= u || v >= n64 || (i > 0 &&
            (u < s->edge_u[i - 1] || (u == s->edge_u[i - 1] && v <= s->edge_v[i - 1])))) return 0;
        s->edge_u[i] = u;
        s->edge_v[i] = v;
        supplied[u][v] = supplied[v][u] = 1;
    }

    uint8_t expected[MAX_N][MAX_N] = {{0}};
    for (int64_t a0 = 0; a0 < n64; ++a0) {
        for (int64_t b0 = a0 + 1; b0 < n64; ++b0) {
            for (int64_t c0 = b0 + 1; c0 < n64; ++c0) {
                int64_t a = a0, b = b0, c = c0;
                const int64_t sign = orient(s, a, b, c);
                if (sign < 0) { const int64_t t = b; b = c; c = t; }
                int empty = 1;
                for (int64_t p = 0; p < n64; ++p) {
                    if (p != a && p != b && p != c && incircle_det(s, a, b, c, p) > 0) {
                        empty = 0;
                        break;
                    }
                }
                if (empty) {
                    if (s->face_count >= MAX_FACES) return 0;
                    int64_t fa = a, fb = b, fc = c;
                    sort_three(&fa, &fb, &fc);
                    s->face_a[s->face_count] = fa;
                    s->face_b[s->face_count] = fb;
                    s->face_c[s->face_count] = fc;
                    ++s->face_count;
                    expected[a][b] = expected[b][a] = 1;
                    expected[a][c] = expected[c][a] = 1;
                    expected[b][c] = expected[c][b] = 1;
                }
            }
        }
    }
    for (int64_t a = 0; a < n64; ++a)
        for (int64_t b = a + 1; b < n64; ++b)
            if (supplied[a][b] != expected[a][b]) return 0;

    for (int64_t a = 0; a < n64; ++a) {
        for (int64_t b = a + 1; b < n64; ++b) {
            int positive = 0, negative = 0;
            for (int64_t p = 0; p < n64; ++p) {
                if (p == a || p == b) continue;
                const int64_t side = orient(s, a, b, p);
                positive |= side > 0;
                negative |= side < 0;
            }
            if (!(positive && negative)) s->hull[a] = s->hull[b] = 1;
        }
    }
    for (size_t i = 0; i < m; ++i)
        if (!add_rotation_neighbor(s, s->edge_u[i], s->edge_v[i])) return 0;
    sort_rotations(s);
    *n_out = n;
    return 1;
}

static int build_mst_and_contour(State *s, size_t n) {
    size_t order[MAX_EDGES];
    for (size_t i = 0; i < s->edge_count; ++i) order[i] = i;
    for (size_t i = 1; i < s->edge_count; ++i) {
        const size_t key = order[i];
        size_t pos = i;
        while (pos > 0) {
            const size_t prev = order[pos - 1];
            const int64_t prev_len = distance_squared(s, s->edge_u[prev], s->edge_v[prev]);
            const int64_t key_len = distance_squared(s, s->edge_u[key], s->edge_v[key]);
            if (prev_len < key_len || (prev_len == key_len &&
                (s->edge_u[prev] < s->edge_u[key] ||
                 (s->edge_u[prev] == s->edge_u[key] && s->edge_v[prev] <= s->edge_v[key])))) break;
            order[pos] = prev;
            --pos;
        }
        order[pos] = key;
    }
    int64_t parent[MAX_N], component_size[MAX_N];
    for (size_t i = 0; i < n; ++i) { parent[i] = (int64_t)i; component_size[i] = 1; }
    size_t chosen = 0;
    for (size_t rank = 0; rank < s->edge_count; ++rank) {
        const size_t e = order[rank];
        const int64_t u = s->edge_u[e], v = s->edge_v[e];
        int64_t a = u, b = v;
        while (parent[a] != a) { parent[a] = parent[parent[a]]; a = parent[a]; }
        while (parent[b] != b) { parent[b] = parent[parent[b]]; b = parent[b]; }
        if (a == b) continue;
        if (component_size[a] < component_size[b]) { const int64_t t = a; a = b; b = t; }
        parent[b] = a;
        component_size[a] += component_size[b];
        s->tree[u][v] = s->tree[v][u] = 1;
        s->kept[u][v] = s->kept[v][u] = 1;
        s->tree_rotation[u][s->tree_degree[u]++] = v;
        s->tree_rotation[v][s->tree_degree[v]++] = u;
        ++chosen;
    }
    if (chosen != n - 1) return 0;
    for (int64_t v = 0; v < (int64_t)n; ++v) {
        for (size_t i = 1; i < s->tree_degree[v]; ++i) {
            const int64_t key = s->tree_rotation[v][i];
            size_t pos = i;
            while (pos > 0 && angle_less(s, v, key, s->tree_rotation[v][pos - 1])) {
                s->tree_rotation[v][pos] = s->tree_rotation[v][pos - 1];
                --pos;
            }
            s->tree_rotation[v][pos] = key;
        }
    }
    for (size_t i = 0; i < s->edge_count; ++i) {
        const int64_t u = s->edge_u[i], v = s->edge_v[i];
        const double length = sqrt((double)distance_squared(s, u, v));
        s->weight[u][v] = s->weight[v][u] = length;
    }

    int64_t first_u = MAX_N, first_v = MAX_N;
    for (int64_t u = 0; u < (int64_t)n; ++u)
        for (int64_t v = 0; v < (int64_t)n; ++v)
            if (s->tree[u][v] && (u < first_u || (u == first_u && v < first_v))) {
                first_u = u;
                first_v = v;
            }
    if (first_u == MAX_N) return 0;
    const size_t expected_darts = 2 * (n - 1);
    s->contour_u[0] = first_u;
    s->contour_v[0] = first_v;
    s->contour_length = 1;
    while (s->contour_length < expected_darts) {
        const size_t last = s->contour_length - 1;
        int64_t next_u, next_v;
        if (!cw_tree_next(s, s->contour_u[last], s->contour_v[last], &next_u, &next_v)) return 0;
        if (next_u == first_u && next_v == first_v) break;
        for (size_t i = 0; i < s->contour_length; ++i)
            if (s->contour_u[i] == next_u && s->contour_v[i] == next_v) return 0;
        s->contour_u[s->contour_length] = next_u;
        s->contour_v[s->contour_length] = next_v;
        ++s->contour_length;
    }
    if (s->contour_length != expected_darts) return 0;
    int64_t close_u, close_v;
    return cw_tree_next(s, s->contour_u[s->contour_length - 1],
                        s->contour_v[s->contour_length - 1], &close_u, &close_v)
        && close_u == first_u && close_v == first_v;
}

static int run_algorithm(State *s, size_t *absorbed_out, size_t *shortcut_out,
                         size_t n) {
    for (size_t i = 0; i < s->contour_length; ++i)
        if (!push_candidate(s, s->contour_u[i], s->contour_v[i])) return 0;
    size_t absorbed = 0;
    size_t steps = 0;
    while (s->stack_size > 0 && steps < 2 * MAX_EDGES) {
        const size_t top = --s->stack_size;
        const int64_t v = s->stack_u[top], w = s->stack_v[top];
        if (!eligible(s, v, w)) continue;
        const int at = contour_find(s, v, w);
        const size_t next_at = ((size_t)at + 1) % s->contour_length;
        const int64_t u = s->contour_v[next_at];
        const double path_weight = s->weight[v][w] + s->weight[w][u];
        const double chord_length = sqrt((double)distance_squared(s, v, u));
        if (path_weight > 2.0 * chord_length) s->kept[v][u] = s->kept[u][v] = 1;
        else s->weight[v][u] = path_weight;

        if (next_at == 0) {
            for (size_t i = 0; i + 1 < s->contour_length; ++i) {
                s->contour_u[i] = s->contour_u[i + 1];
                s->contour_v[i] = s->contour_v[i + 1];
            }
            --s->contour_length;
            s->contour_u[s->contour_length - 1] = v;
            s->contour_v[s->contour_length - 1] = u;
        } else {
            s->contour_u[at] = v;
            s->contour_v[at] = u;
            for (size_t i = next_at; i + 1 < s->contour_length; ++i) {
                s->contour_u[i] = s->contour_u[i + 1];
                s->contour_v[i] = s->contour_v[i + 1];
            }
            --s->contour_length;
        }
        canonicalize_contour(s);
        ++absorbed;
        ++steps;

        const int chord_at = contour_find(s, v, u);
        if (chord_at < 0) return 0;
        if (!push_candidate(s, v, u)) return 0;
        const size_t left_at = ((size_t)chord_at + s->contour_length - 1) % s->contour_length;
        if (!push_candidate(s, s->contour_u[left_at], s->contour_v[left_at])) return 0;
    }
    if (steps >= 2 * MAX_EDGES && s->stack_size > 0) return 0;
    *absorbed_out = absorbed;
    *shortcut_out = 0;
    for (size_t u = 0; u < n; ++u)
        for (size_t v = u + 1; v < n; ++v)
            if (s->kept[u][v] && !s->tree[u][v]) ++*shortcut_out;
    return 1;
}

static void write_i64_le(uint8_t *output, size_t word, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[word * 8 + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t levcopoulos_lingas_planar_geometric_spanner(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 14 || length > MAX_INPUT) return -1;
    State state = {0};
    size_t n = 0;
    if (!validate_and_parse(&state, input, length, &n)
        || !build_mst_and_contour(&state, n)) return -1;
    size_t absorbed = 0, shortcuts = 0;
    if (!run_algorithm(&state, &absorbed, &shortcuts, n)) return -1;
    int64_t words[3 + 2 * MAX_EDGES];
    size_t word_count = 3;
    words[0] = (int64_t)absorbed;
    words[1] = (int64_t)shortcuts;
    words[2] = 0;
    for (size_t u = 0; u < n; ++u) {
        for (size_t v = u + 1; v < n; ++v) {
            if (state.kept[u][v]) {
                words[word_count++] = (int64_t)u;
                words[word_count++] = (int64_t)v;
                ++words[2];
            }
        }
    }
    const size_t output_bytes = word_count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < word_count; ++i) write_i64_le(output, i, words[i]);
    return (int64_t)output_bytes;
}
