#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxVertices = 8;
constexpr int kMaxEdges = 28;
constexpr std::size_t kMaxParseableLength = 87;

struct LouvainState {
    int node_count = 0;
    std::array<int, kMaxVertices> node_key{};
    std::array<std::uint16_t, kMaxVertices> original_mask{};
    std::array<std::int64_t, kMaxVertices * kMaxVertices> adjacency{};
};

std::int64_t modularity_score(const LouvainState& state,
                              const std::array<int, kMaxVertices>& community) noexcept {
    std::array<std::int64_t, kMaxVertices> degree{};
    std::array<std::int64_t, kMaxVertices> community_degree{};
    std::int64_t total_degree = 0;
    std::int64_t internal_directed_weight = 0;
    for (int node = 0; node < state.node_count; ++node) {
        for (int other = 0; other < state.node_count; ++other)
            degree[node] += state.adjacency[node * kMaxVertices + other];
        total_degree += degree[node];
        community_degree[community[node]] += degree[node];
    }
    for (int node = 0; node < state.node_count; ++node)
        for (int other = 0; other < state.node_count; ++other)
            if (community[node] == community[other])
                internal_directed_weight += state.adjacency[node * kMaxVertices + other];

    std::int64_t squared_community_degree = 0;
    for (int group = 0; group < state.node_count; ++group)
        squared_community_degree += community_degree[group] * community_degree[group];
    return total_degree * internal_directed_weight - squared_community_degree;
}

void fill_community_keys(const LouvainState& state,
                         const std::array<int, kMaxVertices>& community,
                         std::array<int, kMaxVertices>& keys) noexcept {
    keys.fill(kMaxVertices);
    for (int node = 0; node < state.node_count; ++node) {
        const int group = community[node];
        if (state.node_key[node] < keys[group]) keys[group] = state.node_key[node];
    }
}

void aggregate_communities(LouvainState& state,
                           const std::array<int, kMaxVertices>& community) noexcept {
    std::array<int, kMaxVertices> keys{};
    fill_community_keys(state, community, keys);

    std::array<int, kMaxVertices> order{};
    int group_count = 0;
    for (int group = 0; group < state.node_count; ++group) {
        if (keys[group] >= kMaxVertices) continue;
        int insert_at = group_count;
        while (insert_at > 0 && keys[order[insert_at - 1]] > keys[group]) {
            order[insert_at] = order[insert_at - 1];
            --insert_at;
        }
        order[insert_at] = group;
        ++group_count;
    }

    std::array<int, kMaxVertices> remap{};
    remap.fill(-1);
    for (int index = 0; index < group_count; ++index) remap[order[index]] = index;

    std::array<int, kMaxVertices> next_keys{};
    std::array<std::uint16_t, kMaxVertices> next_masks{};
    std::array<std::int64_t, kMaxVertices * kMaxVertices> next_adjacency{};
    for (int index = 0; index < group_count; ++index)
        next_keys[index] = keys[order[index]];
    for (int node = 0; node < state.node_count; ++node) {
        const int next_node = remap[community[node]];
        next_masks[next_node] |= state.original_mask[node];
        for (int other = 0; other < state.node_count; ++other) {
            const int next_other = remap[community[other]];
            next_adjacency[next_node * kMaxVertices + next_other] +=
                state.adjacency[node * kMaxVertices + other];
        }
    }

    state.node_count = group_count;
    state.node_key = next_keys;
    state.original_mask = next_masks;
    state.adjacency = next_adjacency;
}

std::int64_t pack_final_result(const LouvainState& state) noexcept {
    std::array<int, kMaxVertices> labels{};
    for (int node = 0; node < state.node_count; ++node) {
        for (int vertex = 0; vertex < kMaxVertices; ++vertex) {
            if ((state.original_mask[node] & (std::uint16_t{1} << vertex)) != 0)
                labels[vertex] = state.node_key[node];
        }
    }

    std::int64_t result = static_cast<std::int64_t>(state.node_count) << 24;
    for (int vertex = 0; vertex < kMaxVertices; ++vertex)
        result += static_cast<std::int64_t>(labels[vertex]) << (3 * vertex);
    return result;
}
}

extern "C" std::int64_t louvain_multilevel_community_detection(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > kMaxParseableLength) return -1;
    const auto vertex_count_value = input[0];
    const auto edge_count_value = input[1];
    if (vertex_count_value < 2 || vertex_count_value > kMaxVertices ||
        edge_count_value < 1 || edge_count_value > kMaxEdges ||
        length != 2 + 3 * static_cast<std::size_t>(edge_count_value)) return -1;

    LouvainState state{};
    state.node_count = static_cast<int>(vertex_count_value);
    for (int vertex = 0; vertex < state.node_count; ++vertex) {
        state.node_key[vertex] = vertex;
        state.original_mask[vertex] = static_cast<std::uint16_t>(1u << vertex);
    }

    int previous_from = -1;
    int previous_to = -1;
    for (int edge = 0; edge < static_cast<int>(edge_count_value); ++edge) {
        const auto from_value = input[2 + 3 * static_cast<std::size_t>(edge)];
        const auto to_value = input[3 + 3 * static_cast<std::size_t>(edge)];
        const auto weight_value = input[4 + 3 * static_cast<std::size_t>(edge)];
        if (from_value < 0 || from_value >= vertex_count_value || to_value < 0 ||
            to_value >= vertex_count_value || from_value >= to_value ||
            weight_value < 1 || weight_value > 7) return -1;
        const int from = static_cast<int>(from_value);
        const int to = static_cast<int>(to_value);
        if (edge > 0 && (from < previous_from || (from == previous_from && to <= previous_to)))
            return -1;
        previous_from = from;
        previous_to = to;
        state.adjacency[from * kMaxVertices + to] = weight_value;
        state.adjacency[to * kMaxVertices + from] = weight_value;
    }

    for (;;) {
        std::array<int, kMaxVertices> community{};
        for (int node = 0; node < state.node_count; ++node) community[node] = node;
        bool any_move = false;

        for (;;) {
            bool sweep_moved = false;
            for (int node = 0; node < state.node_count; ++node) {
                std::array<int, kMaxVertices> community_keys{};
                fill_community_keys(state, community, community_keys);
                const std::int64_t current_score = modularity_score(state, community);
                std::array<bool, kMaxVertices> considered{};
                int best_target = -1;
                std::int64_t best_delta = 0;
                int best_target_key = kMaxVertices;

                for (int other = 0; other < state.node_count; ++other) {
                    if (other == node || state.adjacency[node * kMaxVertices + other] <= 0)
                        continue;
                    const int target = community[other];
                    if (target == community[node] || considered[target]) continue;
                    considered[target] = true;

                    const int previous_community = community[node];
                    community[node] = target;
                    const std::int64_t candidate_score = modularity_score(state, community);
                    community[node] = previous_community;
                    const std::int64_t delta = candidate_score - current_score;
                    if (delta > 0 && (delta > best_delta ||
                        (delta == best_delta && community_keys[target] < best_target_key))) {
                        best_target = target;
                        best_delta = delta;
                        best_target_key = community_keys[target];
                    }
                }

                if (best_target >= 0) {
                    community[node] = best_target;
                    sweep_moved = true;
                    any_move = true;
                }
            }
            if (!sweep_moved) break;
        }

        if (!any_move) break;
        aggregate_communities(state, community);
    }

    return pack_final_result(state);
}
