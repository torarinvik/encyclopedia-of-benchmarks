#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 8
#define MAX_EDGES 28
#define MAX_PARSEABLE_LENGTH 87

typedef struct {
    int node_count;
    int node_key[MAX_VERTICES];
    uint16_t original_mask[MAX_VERTICES];
    int64_t adjacency[MAX_VERTICES * MAX_VERTICES];
} LouvainState;

static int64_t modularity_score(const LouvainState *state, const int *community) {
    int64_t degree[MAX_VERTICES] = {0};
    int64_t community_degree[MAX_VERTICES] = {0};
    int64_t total_degree = 0;
    int64_t internal_directed_weight = 0;
    for (int node = 0; node < state->node_count; ++node) {
        for (int other = 0; other < state->node_count; ++other)
            degree[node] += state->adjacency[node * MAX_VERTICES + other];
        total_degree += degree[node];
        community_degree[community[node]] += degree[node];
    }
    for (int node = 0; node < state->node_count; ++node)
        for (int other = 0; other < state->node_count; ++other)
            if (community[node] == community[other])
                internal_directed_weight += state->adjacency[node * MAX_VERTICES + other];

    int64_t squared_community_degree = 0;
    for (int group = 0; group < state->node_count; ++group)
        squared_community_degree += community_degree[group] * community_degree[group];
    return total_degree * internal_directed_weight - squared_community_degree;
}

static int fill_community_keys(const LouvainState *state, const int *community,
                               int *keys) {
    for (int group = 0; group < MAX_VERTICES; ++group) keys[group] = MAX_VERTICES;
    for (int node = 0; node < state->node_count; ++node) {
        const int group = community[node];
        if (state->node_key[node] < keys[group]) keys[group] = state->node_key[node];
    }
    int count = 0;
    for (int group = 0; group < state->node_count; ++group)
        if (keys[group] < MAX_VERTICES) ++count;
    return count;
}

static void aggregate_communities(LouvainState *state, const int *community) {
    int keys[MAX_VERTICES];
    fill_community_keys(state, community, keys);

    int order[MAX_VERTICES];
    int group_count = 0;
    for (int group = 0; group < state->node_count; ++group) {
        if (keys[group] >= MAX_VERTICES) continue;
        int insert_at = group_count;
        while (insert_at > 0 && keys[order[insert_at - 1]] > keys[group]) {
            order[insert_at] = order[insert_at - 1];
            --insert_at;
        }
        order[insert_at] = group;
        ++group_count;
    }

    int remap[MAX_VERTICES];
    for (int group = 0; group < MAX_VERTICES; ++group) remap[group] = -1;
    for (int index = 0; index < group_count; ++index) remap[order[index]] = index;

    int next_keys[MAX_VERTICES] = {0};
    uint16_t next_masks[MAX_VERTICES] = {0};
    int64_t next_adjacency[MAX_VERTICES * MAX_VERTICES] = {0};
    for (int index = 0; index < group_count; ++index) {
        const int group = order[index];
        next_keys[index] = keys[group];
    }
    for (int node = 0; node < state->node_count; ++node) {
        const int next_node = remap[community[node]];
        next_masks[next_node] |= state->original_mask[node];
        for (int other = 0; other < state->node_count; ++other) {
            const int next_other = remap[community[other]];
            next_adjacency[next_node * MAX_VERTICES + next_other] +=
                state->adjacency[node * MAX_VERTICES + other];
        }
    }

    state->node_count = group_count;
    for (int node = 0; node < MAX_VERTICES; ++node) {
        state->node_key[node] = next_keys[node];
        state->original_mask[node] = next_masks[node];
    }
    for (int index = 0; index < MAX_VERTICES * MAX_VERTICES; ++index)
        state->adjacency[index] = next_adjacency[index];
}

static int pack_final_result(const LouvainState *state) {
    int labels[MAX_VERTICES] = {0};
    for (int node = 0; node < state->node_count; ++node) {
        for (int vertex = 0; vertex < MAX_VERTICES; ++vertex) {
            if ((state->original_mask[node] & (uint16_t)(1u << vertex)) != 0)
                labels[vertex] = state->node_key[node];
        }
    }
    int result = state->node_count << 24;
    for (int vertex = 0; vertex < MAX_VERTICES; ++vertex)
        result += labels[vertex] << (3 * vertex);
    return result;
}

int64_t louvain_multilevel_community_detection(const int64_t *input, size_t length) {
    if (input == NULL || length < 2u || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t vertex_count_value = input[0];
    const int64_t edge_count_value = input[1];
    if (vertex_count_value < 2 || vertex_count_value > MAX_VERTICES ||
        edge_count_value < 1 || edge_count_value > MAX_EDGES ||
        length != 2u + 3u * (size_t)edge_count_value) return -1;

    LouvainState state = {0};
    state.node_count = (int)vertex_count_value;
    for (int vertex = 0; vertex < state.node_count; ++vertex) {
        state.node_key[vertex] = vertex;
        state.original_mask[vertex] = (uint16_t)(1u << vertex);
    }

    int previous_from = -1;
    int previous_to = -1;
    for (int edge = 0; edge < (int)edge_count_value; ++edge) {
        const int64_t from_value = input[2u + 3u * (size_t)edge];
        const int64_t to_value = input[3u + 3u * (size_t)edge];
        const int64_t weight_value = input[4u + 3u * (size_t)edge];
        if (from_value < 0 || from_value >= vertex_count_value || to_value < 0 ||
            to_value >= vertex_count_value || from_value >= to_value ||
            weight_value < 1 || weight_value > 7) return -1;
        const int from = (int)from_value;
        const int to = (int)to_value;
        if (edge > 0 && (from < previous_from || (from == previous_from && to <= previous_to)))
            return -1;
        previous_from = from;
        previous_to = to;
        state.adjacency[from * MAX_VERTICES + to] = weight_value;
        state.adjacency[to * MAX_VERTICES + from] = weight_value;
    }

    for (;;) {
        int community[MAX_VERTICES];
        for (int node = 0; node < state.node_count; ++node) community[node] = node;
        int any_move = 0;

        for (;;) {
            int sweep_moved = 0;
            for (int node = 0; node < state.node_count; ++node) {
                int community_keys[MAX_VERTICES];
                fill_community_keys(&state, community, community_keys);
                const int64_t current_score = modularity_score(&state, community);
                unsigned char considered[MAX_VERTICES] = {0};
                int best_target = -1;
                int64_t best_delta = 0;
                int best_target_key = MAX_VERTICES;
                for (int other = 0; other < state.node_count; ++other) {
                    if (other == node || state.adjacency[node * MAX_VERTICES + other] <= 0)
                        continue;
                    const int target = community[other];
                    if (target == community[node] || considered[target]) continue;
                    considered[target] = 1;

                    const int previous_community = community[node];
                    community[node] = target;
                    const int64_t candidate_score = modularity_score(&state, community);
                    community[node] = previous_community;
                    const int64_t delta = candidate_score - current_score;
                    if (delta > 0 && (delta > best_delta ||
                        (delta == best_delta && community_keys[target] < best_target_key))) {
                        best_target = target;
                        best_delta = delta;
                        best_target_key = community_keys[target];
                    }
                }
                if (best_target >= 0) {
                    community[node] = best_target;
                    sweep_moved = 1;
                    any_move = 1;
                }
            }
            if (!sweep_moved) break;
        }

        if (!any_move) break;
        aggregate_communities(&state, community);
    }

    return pack_final_result(&state);
}
