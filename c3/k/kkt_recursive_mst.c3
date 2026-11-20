module kkt_recursive_mst;

const int MAX_N = 16;
const int MAX_M = 16;
const usz MAX_INPUT = 52;

struct KktEdge { int u; int v; int weight; int id; }

fn bool edge_less(KktEdge left, KktEdge right) {
    return left.weight < right.weight ||
        (left.weight == right.weight && left.id < right.id);
}

fn int find_root(int* parent, int vertex) {
    int root = vertex;
    while (parent[root] != root) root = parent[root];
    while (parent[vertex] != vertex) {
        int next = parent[vertex];
        parent[vertex] = root;
        vertex = next;
    }
    return root;
}

fn void join_components(int* parent, int first, int second) {
    int root_first = find_root(parent, first);
    int root_second = find_root(parent, second);
    if (root_first != root_second) parent[root_second] = root_first;
}

fn ulong next_random(ulong* state) {
    state[0] += 0x9E3779B97F4A7C15ul;
    ulong value = state[0];
    value = (value ^ (value >> 30)) * 0xBF58476D1CE4E5B9ul;
    value = (value ^ (value >> 27)) * 0x94D049BB133111EBul;
    return value ^ (value >> 31);
}

fn int path_max_key(int vertex_count, KktEdge* forest, int forest_count,
                    int source, int target) {
    int[MAX_N] parent;
    int[MAX_N] parent_key;
    int[MAX_N] stack;
    for (int vertex = 0; vertex < vertex_count; vertex++) parent[vertex] = -1;
    parent[source] = source;
    int stack_size = 1;
    stack[0] = source;

    while (stack_size > 0 && parent[target] < 0) {
        stack_size -= 1;
        int current = stack[stack_size];
        for (int edge = 0; edge < forest_count; edge++) {
            int next = -1;
            if (forest[edge].u == current) next = forest[edge].v;
            else if (forest[edge].v == current) next = forest[edge].u;
            if (next < 0 || parent[next] >= 0) continue;
            parent[next] = current;
            parent_key[next] = forest[edge].weight * MAX_M + forest[edge].id;
            stack[stack_size] = next;
            stack_size += 1;
        }
    }
    if (parent[target] < 0) return -1;

    int maximum = -1;
    int vertex = target;
    while (vertex != source) {
        if (parent_key[vertex] > maximum) maximum = parent_key[vertex];
        vertex = parent[vertex];
    }
    return maximum;
}

fn ulong solve(int vertex_count, KktEdge* initial_edges, int initial_count,
               ulong* random_state) {
    KktEdge[MAX_M] edges;
    int edge_count = initial_count;
    for (int edge = 0; edge < edge_count; edge++) edges[edge] = initial_edges[edge];
    ulong boruvka_mask = 0;
    if (edge_count == 0) return 0;

    for (int phase = 0; phase < 2 && edge_count > 0; phase++) {
        int[MAX_N] parent;
        int[MAX_N] best_edge;
        for (int vertex = 0; vertex < vertex_count; vertex++) {
            parent[vertex] = vertex;
            best_edge[vertex] = -1;
        }
        for (int edge = 0; edge < edge_count; edge++) {
            int first = edges[edge].u;
            int second = edges[edge].v;
            int previous = best_edge[first];
            if (previous < 0 || edge_less(edges[edge], edges[previous])) best_edge[first] = edge;
            previous = best_edge[second];
            if (previous < 0 || edge_less(edges[edge], edges[previous])) best_edge[second] = edge;
        }

        for (int vertex = 0; vertex < vertex_count; vertex++) {
            int edge = best_edge[vertex];
            if (edge < 0) continue;
            boruvka_mask |= 1ul << edges[edge].id;
            join_components(&parent[0], edges[edge].u, edges[edge].v);
        }

        int[MAX_N] component_id;
        int[MAX_N] root_to_component;
        for (int vertex = 0; vertex < MAX_N; vertex++) {
            component_id[vertex] = -1;
            root_to_component[vertex] = -1;
        }
        int contracted_vertices = 0;
        for (int vertex = 0; vertex < vertex_count; vertex++) {
            int root = find_root(&parent[0], vertex);
            if (root_to_component[root] < 0) {
                root_to_component[root] = contracted_vertices;
                contracted_vertices += 1;
            }
            component_id[vertex] = root_to_component[root];
        }

        KktEdge[MAX_M] contracted;
        int contracted_count = 0;
        for (int edge = 0; edge < edge_count; edge++) {
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
            for (int prior = 0; prior < contracted_count; prior++)
                if (contracted[prior].u == candidate.u && contracted[prior].v == candidate.v) {
                    duplicate = prior;
                    break;
                }
            if (duplicate < 0) {
                contracted[contracted_count] = candidate;
                contracted_count += 1;
            } else if (edge_less(candidate, contracted[duplicate])) {
                contracted[duplicate] = candidate;
            }
        }
        vertex_count = contracted_vertices;
        edge_count = contracted_count;
        for (int edge = 0; edge < edge_count; edge++) edges[edge] = contracted[edge];
    }

    if (edge_count == 0) return boruvka_mask;

    KktEdge[MAX_M] ordered;
    for (int edge = 0; edge < edge_count; edge++) ordered[edge] = edges[edge];
    for (int index = 1; index < edge_count; index++) {
        KktEdge item = ordered[index];
        int position = index;
        while (position > 0 && edge_less(item, ordered[position - 1])) {
            ordered[position] = ordered[position - 1];
            position -= 1;
        }
        ordered[position] = item;
    }

    KktEdge[MAX_M] sampled;
    int sampled_count = 0;
    for (int edge = 0; edge < edge_count; edge++)
        if ((next_random(random_state) & 1ul) != 0) {
            sampled[sampled_count] = ordered[edge];
            sampled_count += 1;
        }

    ulong sampled_mask = solve(vertex_count, &sampled[0], sampled_count, random_state);
    KktEdge[MAX_M] forest;
    int forest_count = 0;
    for (int edge = 0; edge < sampled_count; edge++)
        if ((sampled_mask & (1ul << sampled[edge].id)) != 0) {
            forest[forest_count] = sampled[edge];
            forest_count += 1;
        }

    KktEdge[MAX_M] light;
    int light_count = 0;
    for (int edge = 0; edge < edge_count; edge++) {
        int path_max = path_max_key(vertex_count, &forest[0], forest_count,
                                    edges[edge].u, edges[edge].v);
        int edge_key = edges[edge].weight * MAX_M + edges[edge].id;
        if (path_max < 0 || edge_key <= path_max) {
            light[light_count] = edges[edge];
            light_count += 1;
        }
    }

    return boruvka_mask | solve(vertex_count, &light[0], light_count, random_state);
}

fn long kkt_recursive_mst(long* input, usz length) @export("kkt_recursive_mst") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n_value = input[0], m_value = input[1], seed_value = input[2];
    if (n_value < 1 || n_value > MAX_N || m_value < 0 || m_value > MAX_M || seed_value < 0)
        return -1;
    int vertex_count = (int)n_value;
    int edge_count = (int)m_value;
    if (length != 3 + 3 * (usz)edge_count) return -1;

    KktEdge[MAX_M] edges;
    for (int edge = 0; edge < edge_count; edge++) {
        long u = input[3 + 3 * (usz)edge];
        long v = input[4 + 3 * (usz)edge];
        long weight = input[5 + 3 * (usz)edge];
        if (u < 0 || u >= v || v >= n_value || weight < 0 || weight > 255) return -1;
        for (int prior = 0; prior < edge; prior++)
            if (edges[prior].u == (int)u && edges[prior].v == (int)v) return -1;
        edges[edge].u = (int)u;
        edges[edge].v = (int)v;
        edges[edge].weight = (int)weight;
        edges[edge].id = edge;
    }

    ulong random_state = (ulong)seed_value;
    return (long)solve(vertex_count, &edges[0], edge_count, &random_state);
}
