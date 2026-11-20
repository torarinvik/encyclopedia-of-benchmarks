module louvain_multilevel_community_detection;

const int MAX_VERTICES = 8;
const int MAX_EDGES = 28;
const usz MAX_PARSEABLE_LENGTH = 87;

struct LouvainState {
    int node_count;
    int[8] node_key;
    int[8] original_mask;
    long[64] adjacency;
}

fn long modularity_score(LouvainState* state, int* community) {
    long[8] degree, community_degree;
    for (int node = 0; node < MAX_VERTICES; node++) {
        degree[node] = 0;
        community_degree[node] = 0;
    }
    long total_degree = 0;
    long internal_directed_weight = 0;
    for (int node = 0; node < state.node_count; node++) {
        for (int other = 0; other < state.node_count; other++)
            degree[node] += state.adjacency[node * MAX_VERTICES + other];
        total_degree += degree[node];
        community_degree[community[node]] += degree[node];
    }
    for (int node = 0; node < state.node_count; node++)
        for (int other = 0; other < state.node_count; other++)
            if (community[node] == community[other])
                internal_directed_weight += state.adjacency[node * MAX_VERTICES + other];

    long squared_community_degree = 0;
    for (int group = 0; group < state.node_count; group++)
        squared_community_degree += community_degree[group] * community_degree[group];
    return total_degree * internal_directed_weight - squared_community_degree;
}

fn int fill_community_keys(LouvainState* state, int* community, int* keys) {
    for (int group = 0; group < MAX_VERTICES; group++) keys[group] = MAX_VERTICES;
    for (int node = 0; node < state.node_count; node++) {
        int group = community[node];
        if (state.node_key[node] < keys[group]) keys[group] = state.node_key[node];
    }
    int count = 0;
    for (int group = 0; group < state.node_count; group++)
        if (keys[group] < MAX_VERTICES) count++;
    return count;
}

fn void aggregate_communities(LouvainState* state, int* community) {
    int[MAX_VERTICES] keys;
    fill_community_keys(state, community, &keys[0]);

    int[MAX_VERTICES] order;
    int group_count = 0;
    for (int group = 0; group < state.node_count; group++) {
        if (keys[group] >= MAX_VERTICES) continue;
        int insert_at = group_count;
        while (insert_at > 0 && keys[order[insert_at - 1]] > keys[group]) {
            order[insert_at] = order[insert_at - 1];
            insert_at--;
        }
        order[insert_at] = group;
        group_count++;
    }

    int[MAX_VERTICES] remap;
    for (int group = 0; group < MAX_VERTICES; group++) remap[group] = -1;
    for (int index = 0; index < group_count; index++) remap[order[index]] = index;

    int[MAX_VERTICES] next_keys, next_masks;
    long[64] next_adjacency;
    for (int index = 0; index < MAX_VERTICES; index++) {
        next_keys[index] = 0;
        next_masks[index] = 0;
    }
    for (int index = 0; index < MAX_VERTICES * MAX_VERTICES; index++) next_adjacency[index] = 0;
    for (int index = 0; index < group_count; index++) next_keys[index] = keys[order[index]];
    for (int node = 0; node < state.node_count; node++) {
        int next_node = remap[community[node]];
        next_masks[next_node] |= state.original_mask[node];
        for (int other = 0; other < state.node_count; other++) {
            int next_other = remap[community[other]];
            next_adjacency[next_node * MAX_VERTICES + next_other] +=
                state.adjacency[node * MAX_VERTICES + other];
        }
    }

    state.node_count = group_count;
    for (int node = 0; node < MAX_VERTICES; node++) {
        state.node_key[node] = next_keys[node];
        state.original_mask[node] = next_masks[node];
    }
    for (int index = 0; index < MAX_VERTICES * MAX_VERTICES; index++)
        state.adjacency[index] = next_adjacency[index];
}

fn long pack_final_result(LouvainState* state) {
    int[MAX_VERTICES] labels;
    for (int vertex = 0; vertex < MAX_VERTICES; vertex++) labels[vertex] = 0;
    for (int node = 0; node < state.node_count; node++) {
        for (int vertex = 0; vertex < MAX_VERTICES; vertex++) {
            if ((state.original_mask[node] & (1 << vertex)) != 0)
                labels[vertex] = state.node_key[node];
        }
    }
    long result = (long)state.node_count << 24;
    for (int vertex = 0; vertex < MAX_VERTICES; vertex++)
        result += (long)labels[vertex] << (3 * vertex);
    return result;
}

fn long louvain_multilevel_community_detection(long* input, usz length)
    @export("louvain_multilevel_community_detection") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_LENGTH) return -1;
    long vertex_count_value = input[0], edge_count_value = input[1];
    if (vertex_count_value < 2 || vertex_count_value > MAX_VERTICES ||
        edge_count_value < 1 || edge_count_value > MAX_EDGES ||
        length != 2 + 3 * (usz)edge_count_value) return -1;

    LouvainState state = {};
    state.node_count = (int)vertex_count_value;
    for (int vertex = 0; vertex < state.node_count; vertex++) {
        state.node_key[vertex] = vertex;
        state.original_mask[vertex] = 1 << vertex;
    }

    int previous_from = -1, previous_to = -1;
    for (int edge = 0; edge < (int)edge_count_value; edge++) {
        long from_value = input[2 + 3 * (usz)edge];
        long to_value = input[3 + 3 * (usz)edge];
        long weight_value = input[4 + 3 * (usz)edge];
        if (from_value < 0 || from_value >= vertex_count_value || to_value < 0 ||
            to_value >= vertex_count_value || from_value >= to_value ||
            weight_value < 1 || weight_value > 7) return -1;
        int from = (int)from_value, to = (int)to_value;
        if (edge > 0 && (from < previous_from || (from == previous_from && to <= previous_to))) return -1;
        previous_from = from;
        previous_to = to;
        state.adjacency[from * MAX_VERTICES + to] = weight_value;
        state.adjacency[to * MAX_VERTICES + from] = weight_value;
    }

    while (true) {
        int[MAX_VERTICES] community;
        for (int node = 0; node < state.node_count; node++) community[node] = node;
        bool any_move = false;

        while (true) {
            bool sweep_moved = false;
            for (int node = 0; node < state.node_count; node++) {
                int[MAX_VERTICES] community_keys;
                fill_community_keys(&state, &community[0], &community_keys[0]);
                long current_score = modularity_score(&state, &community[0]);
                bool[MAX_VERTICES] considered;
                for (int group = 0; group < MAX_VERTICES; group++) considered[group] = false;
                int best_target = -1;
                long best_delta = 0;
                int best_target_key = MAX_VERTICES;
                for (int other = 0; other < state.node_count; other++) {
                    if (other == node || state.adjacency[node * MAX_VERTICES + other] <= 0) continue;
                    int target = community[other];
                    if (target == community[node] || considered[target]) continue;
                    considered[target] = true;

                    int previous_community = community[node];
                    community[node] = target;
                    long candidate_score = modularity_score(&state, &community[0]);
                    community[node] = previous_community;
                    long delta = candidate_score - current_score;
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
        aggregate_communities(&state, &community[0]);
    }

    return pack_final_result(&state);
}
