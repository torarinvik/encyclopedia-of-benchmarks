#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr int kMaxVertices = 64;
constexpr std::int64_t kMaxEdges = 128;
constexpr std::size_t kMaxInputLength = 2 + 2 * kMaxEdges + 1;

struct BridgeState {
    std::array<int, kMaxVertices> dsu_2ecc{};
    std::array<int, kMaxVertices> dsu_cc{};
    std::array<int, kMaxVertices> dsu_cc_size{};
    std::array<int, kMaxVertices> parent{};
    std::array<int, kMaxVertices> last_visit{};
    int iteration = 0;
    int bridges = 0;
};

int find_2ecc(BridgeState& state, int vertex) noexcept {
    if (vertex == -1) return -1;
    if (state.dsu_2ecc[vertex] == vertex) return vertex;
    state.dsu_2ecc[vertex] = find_2ecc(state, state.dsu_2ecc[vertex]);
    return state.dsu_2ecc[vertex];
}

int find_cc(BridgeState& state, int vertex) noexcept {
    vertex = find_2ecc(state, vertex);
    if (state.dsu_cc[vertex] == vertex) return vertex;
    state.dsu_cc[vertex] = find_cc(state, state.dsu_cc[vertex]);
    return state.dsu_cc[vertex];
}

void make_root(BridgeState& state, int vertex) noexcept {
    vertex = find_2ecc(state, vertex);
    const int root = vertex;
    int child = -1;
    while (vertex != -1) {
        const int next = find_2ecc(state, state.parent[vertex]);
        state.parent[vertex] = child;
        state.dsu_cc[vertex] = root;
        child = vertex;
        vertex = next;
    }
    state.dsu_cc_size[root] = state.dsu_cc_size[child];
}

void merge_path(BridgeState& state, int left, int right) noexcept {
    ++state.iteration;
    std::array<int, kMaxVertices> path_left{};
    std::array<int, kMaxVertices> path_right{};
    int left_length = 0;
    int right_length = 0;
    int lca = -1;
    while (lca == -1) {
        if (left != -1) {
            left = find_2ecc(state, left);
            path_left[left_length++] = left;
            if (state.last_visit[left] == state.iteration) { lca = left; break; }
            state.last_visit[left] = state.iteration;
            left = state.parent[left];
        }
        if (right != -1) {
            right = find_2ecc(state, right);
            path_right[right_length++] = right;
            if (state.last_visit[right] == state.iteration) { lca = right; break; }
            state.last_visit[right] = state.iteration;
            right = state.parent[right];
        }
    }
    for (int index = 0; index < left_length; ++index) {
        const int vertex = path_left[index];
        state.dsu_2ecc[vertex] = lca;
        if (vertex == lca) break;
        --state.bridges;
    }
    for (int index = 0; index < right_length; ++index) {
        const int vertex = path_right[index];
        state.dsu_2ecc[vertex] = lca;
        if (vertex == lca) break;
        --state.bridges;
    }
}

void add_edge(BridgeState& state, int left, int right) noexcept {
    left = find_2ecc(state, left);
    right = find_2ecc(state, right);
    if (left == right) return;
    int left_cc = find_cc(state, left);
    int right_cc = find_cc(state, right);
    if (left_cc != right_cc) {
        ++state.bridges;
        if (state.dsu_cc_size[left_cc] > state.dsu_cc_size[right_cc]) {
            std::swap(left, right);
            std::swap(left_cc, right_cc);
        }
        make_root(state, left);
        state.parent[left] = right;
        state.dsu_cc[left] = right;
        state.dsu_cc_size[right_cc] += state.dsu_cc_size[left];
    } else {
        merge_path(state, left, right);
    }
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>((bits >> (byte * 8)) & 0xffu);
}
} // namespace

extern "C" std::int64_t online_bridge_finding(const std::int64_t* values,
                                               std::size_t length,
                                               std::uint8_t* output,
                                               std::size_t capacity) noexcept {
    if (values == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const std::int64_t raw_vertices = values[0];
    const std::int64_t raw_edges = values[1];
    if (raw_vertices < 1 || raw_vertices > kMaxVertices || raw_edges < 0 || raw_edges > kMaxEdges)
        return -1;
    const std::size_t vertex_count = static_cast<std::size_t>(raw_vertices);
    const std::size_t edge_count = static_cast<std::size_t>(raw_edges);
    if (length != 2 + 2 * edge_count) return -1;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const std::int64_t left = values[2 + 2 * edge];
        const std::int64_t right = values[3 + 2 * edge];
        if (left < 0 || right < 0 || left >= static_cast<std::int64_t>(vertex_count)
            || right >= static_cast<std::int64_t>(vertex_count)) return -1;
    }
    const std::size_t output_bytes = edge_count * 8;
    if (output_bytes > 0 && (output == nullptr || capacity < output_bytes)) return -2;

    BridgeState state{};
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
        state.dsu_2ecc[vertex] = static_cast<int>(vertex);
        state.dsu_cc[vertex] = static_cast<int>(vertex);
        state.dsu_cc_size[vertex] = 1;
        state.parent[vertex] = -1;
    }
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        add_edge(state, static_cast<int>(values[2 + 2 * edge]),
                 static_cast<int>(values[3 + 2 * edge]));
        store_i64_le(output, edge * 8, state.bridges);
    }
    return static_cast<std::int64_t>(output_bytes);
}
