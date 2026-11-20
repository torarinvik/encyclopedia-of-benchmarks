module long_chain_dominant_depth_index;

const usz MAX_N = 64;
const usz MAX_INPUT_LENGTH = 65;

struct Long_Chain_State {
    int[64] parent;
    int[64] first_child;
    int[64] next_sibling;
    int[64] height;
    int[64] heavy;
    int[64] base;
    int[64] count;
    int[64] dominant_depth;
}

fn void solve(Long_Chain_State* state, usz n) {
    for (usz vertex = 0; vertex < n; vertex++) {
        state.height[vertex] = 1;
        state.heavy[vertex] = -1;
        state.first_child[vertex] = -1;
    }
    state.parent[0] = -1;
    for (usz vertex = 1; vertex < n; vertex++) {
        int parent = state.parent[vertex];
        state.next_sibling[vertex] = state.first_child[parent];
        state.first_child[parent] = (int)vertex;
    }

    for (usz reverse = n; reverse > 0; reverse--) {
        usz vertex = reverse - 1;
        int child = state.first_child[vertex];
        int maximum_height = 0;
        while (child >= 0) {
            int child_height = state.height[child];
            if (child_height > maximum_height ||
                (child_height == maximum_height && child < state.heavy[vertex])) {
                maximum_height = child_height;
                state.heavy[vertex] = child;
            }
            child = state.next_sibling[child];
        }
        state.height[vertex] = maximum_height + 1;
    }

    int pool_size = 0;
    for (usz vertex = 0; vertex < n; vertex++) {
        if (vertex == 0 || state.heavy[state.parent[vertex]] != (int)vertex) {
            int current = (int)vertex;
            while (current >= 0) {
                state.base[current] = pool_size++;
                current = state.heavy[current];
            }
        }
    }

    for (usz reverse = n; reverse > 0; reverse--) {
        usz vertex = reverse - 1;
        int base = state.base[vertex];
        state.count[base] = 1;
        int best_depth = 0;
        int best_count = 1;
        int heavy = state.heavy[vertex];
        if (heavy >= 0) {
            best_depth = state.dominant_depth[heavy] + 1;
            best_count = state.count[base + best_depth];
        }
        for (int child = state.first_child[vertex]; child >= 0;
             child = state.next_sibling[child]) {
            if (child == heavy) continue;
            for (int child_depth = 0; child_depth < state.height[child]; child_depth++) {
                int depth = child_depth + 1;
                int slot = base + depth;
                int amount = state.count[slot] + state.count[state.base[child] + child_depth];
                state.count[slot] = amount;
                if (amount > best_count || (amount == best_count && depth < best_depth)) {
                    best_count = amount;
                    best_depth = depth;
                }
            }
        }
        state.dominant_depth[vertex] = best_depth;
    }
}

fn long long_chain_dominant_depth_index(long* input, usz length, char* output,
    usz output_capacity) @export("long_chain_dominant_depth_index") {
    if (input == null || length == 0 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > 64 || length != (usz)n_value) return -1;
    usz n = (usz)n_value;
    for (usz vertex = 1; vertex < n; vertex++)
        if (input[vertex] < 0 || input[vertex] >= (long)vertex) return -1;
    usz required = 8 * n;
    if (output == null || output_capacity < required) return -2;

    Long_Chain_State state = {};
    for (usz vertex = 1; vertex < n; vertex++) state.parent[vertex] = (int)input[vertex];
    solve(&state, n);
    for (usz vertex = 0; vertex < n; vertex++) {
        ulong bits = (ulong)state.dominant_depth[vertex];
        for (usz byte = 0; byte < 8; byte++) output[8*vertex+byte] = (char)(bits >> (8*byte));
    }
    return (long)required;
}
