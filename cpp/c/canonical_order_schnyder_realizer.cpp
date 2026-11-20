#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_INPUT = 49, MAX_DEGREE = 7, MAX_DARTS = 48 };

typedef struct {
    int n;
    int u, v, w;
    int degree[MAX_N];
    int rotation[MAX_N][MAX_DEGREE];
    bool adjacent[MAX_N][MAX_N];
} Embedding;

static int next_active(const Embedding *g, const bool active[MAX_N], int source, int target)
{
    int source_position = -1;
    int remaining = 0;
    for (int i = 0; i < g->degree[target]; ++i) {
        const int neighbor = g->rotation[target][i];
        if (!active[neighbor]) continue;
        ++remaining;
        if (neighbor == source) source_position = i;
    }
    if (remaining < 2 || source_position < 0) return -1;
    for (int step = 1; step <= g->degree[target]; ++step) {
        const int position = (source_position + step) % g->degree[target];
        const int neighbor = g->rotation[target][position];
        if (active[neighbor]) return neighbor;
    }
    return -1;
}

static int face_cycle(const Embedding *g, const bool active[MAX_N], int first, int second,
                      int cycle[MAX_DARTS])
{
    bool seen[MAX_N][MAX_N] = {{false}};
    int source = first, target = second, length = 0;
    for (int step = 0; step < MAX_DARTS; ++step) {
        if (source < 0 || source >= g->n || target < 0 || target >= g->n ||
            !active[source] || !active[target] || !g->adjacent[source][target] || seen[source][target])
            return -1;
        seen[source][target] = true;
        cycle[length++] = source;
        const int following = next_active(g, active, source, target);
        if (following < 0) return -1;
        source = target;
        target = following;
        if (source == first && target == second) return length;
    }
    return -1;
}

static bool parse_embedding(const int64_t *input, size_t length, Embedding *g)
{
    if (input == NULL || length < 4 || length > MAX_INPUT) return false;
    const int64_t n_raw = input[0];
    if (n_raw < 3 || n_raw > MAX_N) return false;
    g->n = (int)n_raw;
    if (input[1] < 0 || input[1] >= n_raw || input[2] < 0 || input[2] >= n_raw ||
        input[3] < 0 || input[3] >= n_raw || input[1] == input[2] ||
        input[1] == input[3] || input[2] == input[3]) return false;
    g->u = (int)input[1]; g->v = (int)input[2]; g->w = (int)input[3];
    size_t offset = 4;
    int degree_sum = 0;
    for (int vertex = 0; vertex < g->n; ++vertex) {
        if (offset >= length) return false;
        const int64_t degree_raw = input[offset++];
        if (degree_raw < 2 || degree_raw >= g->n || degree_raw > MAX_DEGREE ||
            offset + (size_t)degree_raw > length) return false;
        const int degree = (int)degree_raw;
        g->degree[vertex] = degree;
        degree_sum += degree;
        bool row_seen[MAX_N] = {false};
        for (int rank = 0; rank < degree; ++rank) {
            const int64_t neighbor_raw = input[offset++];
            if (neighbor_raw < 0 || neighbor_raw >= g->n || neighbor_raw == vertex ||
                row_seen[neighbor_raw]) return false;
            const int neighbor = (int)neighbor_raw;
            row_seen[neighbor] = true;
            g->rotation[vertex][rank] = neighbor;
            g->adjacent[vertex][neighbor] = true;
        }
    }
    if (offset != length || degree_sum != 6 * g->n - 12) return false;
    int edge_count = 0;
    for (int a = 0; a < g->n; ++a) {
        for (int b = 0; b < g->n; ++b) {
            if (g->adjacent[a][b] != g->adjacent[b][a]) return false;
            if (a < b && g->adjacent[a][b]) ++edge_count;
        }
    }
    if (edge_count != 3 * g->n - 6) return false;
    bool reached[MAX_N] = {false};
    int stack[MAX_N], stack_size = 1, reached_count = 0;
    stack[0] = 0; reached[0] = true;
    while (stack_size > 0) {
        const int vertex = stack[--stack_size];
        ++reached_count;
        for (int neighbor = 0; neighbor < g->n; ++neighbor) {
            if (g->adjacent[vertex][neighbor] && !reached[neighbor]) {
                reached[neighbor] = true;
                stack[stack_size++] = neighbor;
            }
        }
    }
    if (reached_count != g->n) return false;

    bool all_active[MAX_N];
    for (int i = 0; i < g->n; ++i) all_active[i] = true;
    bool seen_dart[MAX_N][MAX_N] = {{false}};
    int face_count = 0, visited_darts = 0;
    for (int source = 0; source < g->n; ++source) {
        for (int target = 0; target < g->n; ++target) {
            if (!g->adjacent[source][target] || seen_dart[source][target]) continue;
            int cycle[MAX_DARTS];
            const int face_length = face_cycle(g, all_active, source, target, cycle);
            if (face_length != 3) return false;
            ++face_count;
            for (int i = 0; i < face_length; ++i) {
                const int a = cycle[i], b = cycle[(i + 1) % face_length];
                if (seen_dart[a][b]) return false;
                seen_dart[a][b] = true;
                ++visited_darts;
            }
        }
    }
    if (face_count != 2 * g->n - 4 || visited_darts != 6 * g->n - 12) return false;
    int outer[MAX_DARTS];
    return face_cycle(g, all_active, g->u, g->v, outer) == 3 &&
           outer[0] == g->u && outer[1] == g->v && outer[2] == g->w;
}

static int boundary_path(const Embedding *g, const bool active[MAX_N], int path[MAX_N])
{
    int cycle[MAX_DARTS];
    const int length = face_cycle(g, active, g->u, g->v, cycle);
    if (length < 3) return -1;
    int count = 0;
    path[count++] = g->u;
    for (int i = length - 1; i >= 2; --i) path[count++] = cycle[i];
    path[count++] = g->v;
    return count;
}

static int peel_choice(const Embedding *g, const int path[MAX_N], int length)
{
    bool chord[MAX_N][MAX_N] = {{false}};
    int chord_count = 0;
    for (int left = 0; left < length; ++left) {
        for (int right = left + 2; right < length; ++right) {
            if (left == 0 && right == length - 1) continue;
            if (g->adjacent[path[left]][path[right]]) {
                chord[left][right] = true;
                ++chord_count;
            }
        }
    }
    bool eligible[MAX_N] = {false};
    if (chord_count == 0) {
        for (int i = 1; i + 1 < length; ++i) eligible[path[i]] = true;
    } else {
        for (int left = 0; left < length; ++left) {
            for (int right = left + 2; right < length; ++right) {
                if (!chord[left][right]) continue;
                bool minimal = true;
                for (int inner_left = left; inner_left < right && minimal; ++inner_left) {
                    for (int inner_right = inner_left + 2; inner_right <= right; ++inner_right) {
                        if (chord[inner_left][inner_right] &&
                            (inner_left != left || inner_right != right)) {
                            minimal = false;
                            break;
                        }
                    }
                }
                if (minimal)
                    for (int i = left + 1; i < right; ++i) eligible[path[i]] = true;
            }
        }
    }
    int choice = -1;
    for (int vertex = 0; vertex < g->n; ++vertex)
        if (eligible[vertex] && (choice < 0 || vertex < choice)) choice = vertex;
    return choice;
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static bool peel_contains(const Embedding *g, const int path[MAX_N], int length, int candidate)
{
    bool chord[MAX_N][MAX_N] = {{false}};
    int chord_count = 0;
    for (int left = 0; left < length; ++left) {
        for (int right = left + 2; right < length; ++right) {
            if (left == 0 && right == length - 1) continue;
            if (g->adjacent[path[left]][path[right]]) {
                chord[left][right] = true;
                ++chord_count;
            }
        }
    }
    bool eligible[MAX_N] = {false};
    if (chord_count == 0) {
        for (int i = 1; i + 1 < length; ++i) eligible[path[i]] = true;
    } else {
        for (int left = 0; left < length; ++left) {
            for (int right = left + 2; right < length; ++right) {
                if (!chord[left][right]) continue;
                bool minimal = true;
                for (int a = left; a < right && minimal; ++a) {
                    for (int b = a + 2; b <= right; ++b) {
                        if (chord[a][b] && (a != left || b != right)) minimal = false;
                    }
                }
                if (minimal)
                    for (int i = left + 1; i < right; ++i) eligible[path[i]] = true;
            }
        }
    }
    return candidate >= 0 && candidate < g->n && eligible[candidate];
}

extern "C" int64_t canonical_order_schnyder_realizer(const int64_t *input, size_t length,
                                                      uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 6 || length > 57) return -1;
    const int64_t n_raw = input[0];
    if (n_raw < 3 || n_raw > MAX_N || length < (size_t)n_raw + 4) return -1;
    const int n = (int)n_raw;
    const size_t graph_length = length - (size_t)n;
    Embedding g = {0};
    if (!parse_embedding(input, graph_length, &g) || g.n != n) return -1;
    int order[MAX_N];
    bool order_seen[MAX_N] = {false};
    const int64_t *order_words = input + graph_length;
    for (int i = 0; i < n; ++i) {
        if (order_words[i] < 0 || order_words[i] >= n || order_seen[order_words[i]]) return -1;
        order[i] = (int)order_words[i];
        order_seen[order[i]] = true;
    }
    if (order[0] != g.u || order[1] != g.v || order[n - 1] != g.w) return -1;

    bool active[MAX_N];
    for (int i = 0; i < n; ++i) active[i] = true;
    int path[MAX_N];
    if (n > 3) {
        active[g.w] = false;
        int path_length = boundary_path(&g, active, path);
        if (path_length < 3) return -1;
        for (int i = n - 2; i >= 3; --i) {
            const int candidate = order[i];
            if (!active[candidate] || candidate == g.u || candidate == g.v ||
                !peel_contains(&g, path, path_length, candidate)) return -1;
            active[candidate] = false;
            path_length = boundary_path(&g, active, path);
            if (path_length < 3) return -1;
        }
        if (path_length != 3 || path[0] != g.u || path[1] != order[2] || path[2] != g.v)
            return -1;
    } else if (order[2] != g.w) return -1;

    int position[MAX_N];
    for (int i = 0; i < n; ++i) position[order[i]] = i;
    int64_t words[1 + 4 * (MAX_N - 3)];
    int count = 0;
    words[count++] = n;
    for (int rank = 2; rank < n - 1; ++rank) {
        const int vertex = order[rank];
        int left = -1, right = -1, boundary_neighbors = 0;
        if (rank == 2) {
            if (!g.adjacent[vertex][g.u] || !g.adjacent[vertex][g.v]) return -1;
            left = g.u; right = g.v;
        } else {
            bool prefix[MAX_N] = {false};
            for (int i = 0; i < rank; ++i) prefix[order[i]] = true;
            const int boundary_length = boundary_path(&g, prefix, path);
            if (boundary_length < 3) return -1;
            bool ended = false;
            for (int i = 0; i < boundary_length; ++i) {
                if (g.adjacent[vertex][path[i]]) {
                    if (ended) return -1;
                    if (left < 0) left = path[i];
                    right = path[i];
                    ++boundary_neighbors;
                } else if (left >= 0) ended = true;
            }
            int all_predecessors = 0;
            for (int i = 0; i < rank; ++i)
                if (g.adjacent[vertex][order[i]]) ++all_predecessors;
            if (boundary_neighbors < 2 || boundary_neighbors != all_predecessors) return -1;
        }
        int successor = -1;
        for (int other = 0; other < n; ++other)
            if (position[other] > rank && g.adjacent[vertex][other] &&
                (successor < 0 || position[other] > position[successor])) successor = other;
        if (successor < 0) return -1;
        words[count++] = vertex;
        words[count++] = left;
        words[count++] = right;
        words[count++] = successor;
    }
    const size_t required = 8u * (size_t)count;
    if (output == NULL || capacity < required) return -2;
    for (int i = 0; i < count; ++i) write_i64_le(output, 8u * (size_t)i, words[i]);
    return (int64_t)required;
}
