#include <stddef.h>
#include <stdint.h>

enum { KKT_MAX_N = 16, KKT_MAX_M = 16, KKT_MAX_INPUT = 52 };

typedef struct {
    int u;
    int v;
    int weight;
    int id;
} KktEdge;

static int kkt_edge_less(KktEdge left, KktEdge right)
{
    return left.weight < right.weight ||
        (left.weight == right.weight && left.id < right.id);
}

static int kkt_find_root(int parent[KKT_MAX_N], int vertex)
{
    int root = vertex;
    while (parent[root] != root) root = parent[root];
    while (parent[vertex] != vertex) {
        int next = parent[vertex];
        parent[vertex] = root;
        vertex = next;
    }
    return root;
}

static void kkt_union(int parent[KKT_MAX_N], int first, int second)
{
    int root_first = kkt_find_root(parent, first);
    int root_second = kkt_find_root(parent, second);
    if (root_first != root_second) parent[root_second] = root_first;
}

static uint64_t kkt_next_random(uint64_t *state)
{
    uint64_t value;
    *state += UINT64_C(0x9E3779B97F4A7C15);
    value = *state;
    value = (value ^ (value >> 30)) * UINT64_C(0xBF58476D1CE4E5B9);
    value = (value ^ (value >> 27)) * UINT64_C(0x94D049BB133111EB);
    return value ^ (value >> 31);
}

static int kkt_path_max_key(int vertex_count, const KktEdge *forest,
                            int forest_count, int source, int target)
{
    int parent[KKT_MAX_N];
    int parent_key[KKT_MAX_N];
    int stack[KKT_MAX_N];
    int stack_size = 0;

    for (int vertex = 0; vertex < vertex_count; ++vertex) parent[vertex] = -1;
    parent[source] = source;
    stack[stack_size++] = source;

    while (stack_size > 0 && parent[target] < 0) {
        int current = stack[--stack_size];
        for (int edge = 0; edge < forest_count; ++edge) {
            int next = -1;
            if (forest[edge].u == current) next = forest[edge].v;
            else if (forest[edge].v == current) next = forest[edge].u;
            if (next < 0 || parent[next] >= 0) continue;
            parent[next] = current;
            parent_key[next] = forest[edge].weight * KKT_MAX_M + forest[edge].id;
            stack[stack_size++] = next;
        }
    }
    if (parent[target] < 0) return -1;

    int maximum = -1;
    for (int vertex = target; vertex != source; vertex = parent[vertex])
        if (parent_key[vertex] > maximum) maximum = parent_key[vertex];
    return maximum;
}

static uint64_t kkt_solve(int vertex_count, const KktEdge *initial_edges,
                          int initial_count, uint64_t *random_state)
{
    KktEdge edges[KKT_MAX_M];
    int edge_count = initial_count;
    for (int edge = 0; edge < edge_count; ++edge) edges[edge] = initial_edges[edge];
    uint64_t boruvka_mask = 0;

    if (edge_count == 0) return 0;

    for (int phase = 0; phase < 2 && edge_count > 0; ++phase) {
        int parent[KKT_MAX_N];
        int best_edge[KKT_MAX_N];
        for (int vertex = 0; vertex < vertex_count; ++vertex) {
            parent[vertex] = vertex;
            best_edge[vertex] = -1;
        }

        for (int edge = 0; edge < edge_count; ++edge) {
            const int endpoints[2] = { edges[edge].u, edges[edge].v };
            for (int side = 0; side < 2; ++side) {
                int vertex = endpoints[side];
                int previous = best_edge[vertex];
                if (previous < 0 || kkt_edge_less(edges[edge], edges[previous]))
                    best_edge[vertex] = edge;
            }
        }

        for (int vertex = 0; vertex < vertex_count; ++vertex) {
            int edge = best_edge[vertex];
            if (edge < 0) continue;
            boruvka_mask |= UINT64_C(1) << edges[edge].id;
            kkt_union(parent, edges[edge].u, edges[edge].v);
        }

        int component_id[KKT_MAX_N];
        int root_to_component[KKT_MAX_N];
        for (int vertex = 0; vertex < KKT_MAX_N; ++vertex) {
            component_id[vertex] = -1;
            root_to_component[vertex] = -1;
        }
        int contracted_vertices = 0;
        for (int vertex = 0; vertex < vertex_count; ++vertex) {
            int root = kkt_find_root(parent, vertex);
            if (root_to_component[root] < 0)
                root_to_component[root] = contracted_vertices++;
            component_id[vertex] = root_to_component[root];
        }

        KktEdge contracted[KKT_MAX_M];
        int contracted_count = 0;
        for (int edge = 0; edge < edge_count; ++edge) {
            KktEdge candidate = edges[edge];
            candidate.u = component_id[candidate.u];
            candidate.v = component_id[candidate.v];
            if (candidate.u == candidate.v) continue;
            if (candidate.u > candidate.v) {
                int temporary = candidate.u;
                candidate.u = candidate.v;
                candidate.v = temporary;
            }

            int duplicate = -1;
            for (int prior = 0; prior < contracted_count; ++prior)
                if (contracted[prior].u == candidate.u &&
                    contracted[prior].v == candidate.v) {
                    duplicate = prior;
                    break;
                }
            if (duplicate < 0) contracted[contracted_count++] = candidate;
            else if (kkt_edge_less(candidate, contracted[duplicate]))
                contracted[duplicate] = candidate;
        }

        vertex_count = contracted_vertices;
        edge_count = contracted_count;
        for (int edge = 0; edge < edge_count; ++edge) edges[edge] = contracted[edge];
    }

    if (edge_count == 0) return boruvka_mask;

    KktEdge ordered[KKT_MAX_M];
    for (int edge = 0; edge < edge_count; ++edge) ordered[edge] = edges[edge];
    for (int index = 1; index < edge_count; ++index) {
        KktEdge item = ordered[index];
        int position = index;
        while (position > 0 && kkt_edge_less(item, ordered[position - 1])) {
            ordered[position] = ordered[position - 1];
            --position;
        }
        ordered[position] = item;
    }

    KktEdge sampled[KKT_MAX_M];
    int sampled_count = 0;
    for (int edge = 0; edge < edge_count; ++edge)
        if ((kkt_next_random(random_state) & UINT64_C(1)) != 0)
            sampled[sampled_count++] = ordered[edge];

    uint64_t sampled_mask = kkt_solve(vertex_count, sampled, sampled_count, random_state);
    KktEdge forest[KKT_MAX_M];
    int forest_count = 0;
    for (int edge = 0; edge < sampled_count; ++edge)
        if ((sampled_mask & (UINT64_C(1) << sampled[edge].id)) != 0)
            forest[forest_count++] = sampled[edge];

    KktEdge light[KKT_MAX_M];
    int light_count = 0;
    for (int edge = 0; edge < edge_count; ++edge) {
        int path_max = kkt_path_max_key(vertex_count, forest, forest_count,
                                        edges[edge].u, edges[edge].v);
        int edge_key = edges[edge].weight * KKT_MAX_M + edges[edge].id;
        if (path_max < 0 || edge_key <= path_max) light[light_count++] = edges[edge];
    }

    return boruvka_mask | kkt_solve(vertex_count, light, light_count, random_state);
}

int64_t kkt_recursive_mst(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > KKT_MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    const int64_t m_value = input[1];
    const int64_t seed_value = input[2];
    if (n_value < 1 || n_value > KKT_MAX_N || m_value < 0 || m_value > KKT_MAX_M ||
        seed_value < 0) return -1;
    const int vertex_count = (int)n_value;
    const int edge_count = (int)m_value;
    if (length != 3 + 3 * (size_t)edge_count) return -1;

    KktEdge edges[KKT_MAX_M];
    for (int edge = 0; edge < edge_count; ++edge) {
        const int64_t u = input[3 + 3 * (size_t)edge];
        const int64_t v = input[4 + 3 * (size_t)edge];
        const int64_t weight = input[5 + 3 * (size_t)edge];
        if (u < 0 || u >= v || v >= n_value || weight < 0 || weight > 255) return -1;
        for (int prior = 0; prior < edge; ++prior)
            if (edges[prior].u == (int)u && edges[prior].v == (int)v) return -1;
        edges[edge].u = (int)u;
        edges[edge].v = (int)v;
        edges[edge].weight = (int)weight;
        edges[edge].id = edge;
    }

    uint64_t random_state = (uint64_t)seed_value;
    return (int64_t)kkt_solve(vertex_count, edges, edge_count, &random_state);
}
