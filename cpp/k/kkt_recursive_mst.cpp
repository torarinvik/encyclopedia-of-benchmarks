#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 16;
constexpr int max_m = 16;
constexpr std::size_t max_input = 52;

struct Edge {
    int u;
    int v;
    int weight;
    int id;
};

bool edge_less(const Edge &left, const Edge &right) noexcept {
    return left.weight < right.weight ||
        (left.weight == right.weight && left.id < right.id);
}

int find_root(std::array<int, max_n> &parent, int vertex) noexcept {
    int root = vertex;
    while (parent[static_cast<std::size_t>(root)] != root)
        root = parent[static_cast<std::size_t>(root)];
    while (parent[static_cast<std::size_t>(vertex)] != vertex) {
        const int next = parent[static_cast<std::size_t>(vertex)];
        parent[static_cast<std::size_t>(vertex)] = root;
        vertex = next;
    }
    return root;
}

void join_components(std::array<int, max_n> &parent, int first, int second) noexcept {
    const int root_first = find_root(parent, first);
    const int root_second = find_root(parent, second);
    if (root_first != root_second)
        parent[static_cast<std::size_t>(root_second)] = root_first;
}

std::uint64_t next_random(std::uint64_t &state) noexcept {
    state += UINT64_C(0x9E3779B97F4A7C15);
    std::uint64_t value = state;
    value = (value ^ (value >> 30)) * UINT64_C(0xBF58476D1CE4E5B9);
    value = (value ^ (value >> 27)) * UINT64_C(0x94D049BB133111EB);
    return value ^ (value >> 31);
}

int path_max_key(int vertex_count, const std::array<Edge, max_m> &forest,
                 int forest_count, int source, int target) noexcept {
    std::array<int, max_n> parent{};
    std::array<int, max_n> parent_key{};
    std::array<int, max_n> stack{};
    for (int vertex = 0; vertex < vertex_count; ++vertex)
        parent[static_cast<std::size_t>(vertex)] = -1;
    parent[static_cast<std::size_t>(source)] = source;
    int stack_size = 1;
    stack[0] = source;

    while (stack_size > 0 && parent[static_cast<std::size_t>(target)] < 0) {
        const int current = stack[static_cast<std::size_t>(--stack_size)];
        for (int edge = 0; edge < forest_count; ++edge) {
            int next = -1;
            if (forest[static_cast<std::size_t>(edge)].u == current)
                next = forest[static_cast<std::size_t>(edge)].v;
            else if (forest[static_cast<std::size_t>(edge)].v == current)
                next = forest[static_cast<std::size_t>(edge)].u;
            if (next < 0 || parent[static_cast<std::size_t>(next)] >= 0) continue;
            parent[static_cast<std::size_t>(next)] = current;
            const Edge &path_edge = forest[static_cast<std::size_t>(edge)];
            parent_key[static_cast<std::size_t>(next)] = path_edge.weight * max_m + path_edge.id;
            stack[static_cast<std::size_t>(stack_size++)] = next;
        }
    }
    if (parent[static_cast<std::size_t>(target)] < 0) return -1;

    int maximum = -1;
    for (int vertex = target; vertex != source;
         vertex = parent[static_cast<std::size_t>(vertex)])
        if (parent_key[static_cast<std::size_t>(vertex)] > maximum)
            maximum = parent_key[static_cast<std::size_t>(vertex)];
    return maximum;
}

std::uint64_t solve(int vertex_count, const std::array<Edge, max_m> &initial_edges,
                    int initial_count, std::uint64_t &random_state) noexcept {
    std::array<Edge, max_m> edges = initial_edges;
    int edge_count = initial_count;
    std::uint64_t boruvka_mask = 0;
    if (edge_count == 0) return 0;

    for (int phase = 0; phase < 2 && edge_count > 0; ++phase) {
        std::array<int, max_n> parent{};
        std::array<int, max_n> best_edge{};
        for (int vertex = 0; vertex < vertex_count; ++vertex) {
            parent[static_cast<std::size_t>(vertex)] = vertex;
            best_edge[static_cast<std::size_t>(vertex)] = -1;
        }
        for (int edge = 0; edge < edge_count; ++edge) {
            const Edge &candidate = edges[static_cast<std::size_t>(edge)];
            int previous = best_edge[static_cast<std::size_t>(candidate.u)];
            if (previous < 0 || edge_less(candidate, edges[static_cast<std::size_t>(previous)]))
                best_edge[static_cast<std::size_t>(candidate.u)] = edge;
            previous = best_edge[static_cast<std::size_t>(candidate.v)];
            if (previous < 0 || edge_less(candidate, edges[static_cast<std::size_t>(previous)]))
                best_edge[static_cast<std::size_t>(candidate.v)] = edge;
        }

        for (int vertex = 0; vertex < vertex_count; ++vertex) {
            const int edge = best_edge[static_cast<std::size_t>(vertex)];
            if (edge < 0) continue;
            const Edge &selected = edges[static_cast<std::size_t>(edge)];
            boruvka_mask |= UINT64_C(1) << selected.id;
            join_components(parent, selected.u, selected.v);
        }

        std::array<int, max_n> component_id{};
        std::array<int, max_n> root_to_component{};
        component_id.fill(-1);
        root_to_component.fill(-1);
        int contracted_vertices = 0;
        for (int vertex = 0; vertex < vertex_count; ++vertex) {
            const int root = find_root(parent, vertex);
            if (root_to_component[static_cast<std::size_t>(root)] < 0)
                root_to_component[static_cast<std::size_t>(root)] = contracted_vertices++;
            component_id[static_cast<std::size_t>(vertex)] =
                root_to_component[static_cast<std::size_t>(root)];
        }

        std::array<Edge, max_m> contracted{};
        int contracted_count = 0;
        for (int edge = 0; edge < edge_count; ++edge) {
            Edge candidate = edges[static_cast<std::size_t>(edge)];
            candidate.u = component_id[static_cast<std::size_t>(candidate.u)];
            candidate.v = component_id[static_cast<std::size_t>(candidate.v)];
            if (candidate.u == candidate.v) continue;
            if (candidate.u > candidate.v) {
                const int temporary = candidate.u;
                candidate.u = candidate.v;
                candidate.v = temporary;
            }

            int duplicate = -1;
            for (int prior = 0; prior < contracted_count; ++prior) {
                const Edge &existing = contracted[static_cast<std::size_t>(prior)];
                if (existing.u == candidate.u && existing.v == candidate.v) {
                    duplicate = prior;
                    break;
                }
            }
            if (duplicate < 0)
                contracted[static_cast<std::size_t>(contracted_count++)] = candidate;
            else if (edge_less(candidate, contracted[static_cast<std::size_t>(duplicate)]))
                contracted[static_cast<std::size_t>(duplicate)] = candidate;
        }
        vertex_count = contracted_vertices;
        edge_count = contracted_count;
        edges = contracted;
    }

    if (edge_count == 0) return boruvka_mask;

    std::array<Edge, max_m> ordered = edges;
    for (int index = 1; index < edge_count; ++index) {
        const Edge item = ordered[static_cast<std::size_t>(index)];
        int position = index;
        while (position > 0 && edge_less(item, ordered[static_cast<std::size_t>(position - 1)])) {
            ordered[static_cast<std::size_t>(position)] =
                ordered[static_cast<std::size_t>(position - 1)];
            --position;
        }
        ordered[static_cast<std::size_t>(position)] = item;
    }

    std::array<Edge, max_m> sampled{};
    int sampled_count = 0;
    for (int edge = 0; edge < edge_count; ++edge)
        if ((next_random(random_state) & UINT64_C(1)) != 0)
            sampled[static_cast<std::size_t>(sampled_count++)] = ordered[static_cast<std::size_t>(edge)];

    const std::uint64_t sampled_mask = solve(vertex_count, sampled, sampled_count, random_state);
    std::array<Edge, max_m> forest{};
    int forest_count = 0;
    for (int edge = 0; edge < sampled_count; ++edge) {
        const Edge &candidate = sampled[static_cast<std::size_t>(edge)];
        if ((sampled_mask & (UINT64_C(1) << candidate.id)) != 0)
            forest[static_cast<std::size_t>(forest_count++)] = candidate;
    }

    std::array<Edge, max_m> light{};
    int light_count = 0;
    for (int edge = 0; edge < edge_count; ++edge) {
        const Edge &candidate = edges[static_cast<std::size_t>(edge)];
        const int path_max = path_max_key(vertex_count, forest, forest_count,
                                          candidate.u, candidate.v);
        const int edge_key = candidate.weight * max_m + candidate.id;
        if (path_max < 0 || edge_key <= path_max)
            light[static_cast<std::size_t>(light_count++)] = candidate;
    }

    return boruvka_mask | solve(vertex_count, light, light_count, random_state);
}
} // namespace

extern "C" std::int64_t kkt_recursive_mst(const std::int64_t *input,
                                          std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > max_input) return -1;
    const std::int64_t n_value = input[0];
    const std::int64_t m_value = input[1];
    const std::int64_t seed_value = input[2];
    if (n_value < 1 || n_value > max_n || m_value < 0 || m_value > max_m || seed_value < 0)
        return -1;
    const int vertex_count = static_cast<int>(n_value);
    const int edge_count = static_cast<int>(m_value);
    if (length != 3 + 3 * static_cast<std::size_t>(edge_count)) return -1;

    std::array<Edge, max_m> edges{};
    for (int edge = 0; edge < edge_count; ++edge) {
        const std::int64_t u = input[3 + 3 * static_cast<std::size_t>(edge)];
        const std::int64_t v = input[4 + 3 * static_cast<std::size_t>(edge)];
        const std::int64_t weight = input[5 + 3 * static_cast<std::size_t>(edge)];
        if (u < 0 || u >= v || v >= n_value || weight < 0 || weight > 255) return -1;
        for (int prior = 0; prior < edge; ++prior) {
            const Edge &previous = edges[static_cast<std::size_t>(prior)];
            if (previous.u == u && previous.v == v) return -1;
        }
        edges[static_cast<std::size_t>(edge)] =
            Edge{static_cast<int>(u), static_cast<int>(v), static_cast<int>(weight), edge};
    }

    std::uint64_t random_state = static_cast<std::uint64_t>(seed_value);
    return static_cast<std::int64_t>(solve(vertex_count, edges, edge_count, random_state));
}
