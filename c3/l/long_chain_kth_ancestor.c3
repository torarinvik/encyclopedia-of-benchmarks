module long_chain_kth_ancestor;

const usz MAX_N = 64;
const usz MAX_Q = 32;
const usz LOG_LEVELS = 6;

struct Long_Chain_Ancestor_State {
    int[64] parent;
    int[64] depth;
    int[64] height;
    int[64] heavy;
    int[64] chain_head;
    int[64] chain_position;
    int[64] chain_base;
    int[64] chain_nodes;
    int[64] head_ancestors;
    int[384] up;
}

fn void solve(Long_Chain_Ancestor_State* state, usz n) {
    state.parent[0] = -1;
    for (usz vertex = 0; vertex < n; vertex++) {
        state.heavy[vertex] = -1;
        state.chain_head[vertex] = -1;
        state.chain_base[vertex] = -1;
        state.height[vertex] = 1;
        if (vertex > 0) state.depth[vertex] = state.depth[state.parent[vertex]] + 1;
    }
    for (usz reverse = n; reverse > 1; reverse--) {
        usz vertex = reverse - 1;
        int parent = state.parent[vertex];
        int old = state.heavy[parent];
        if (old < 0 || state.height[vertex] > state.height[old] ||
            (state.height[vertex] == state.height[old] && (int)vertex < old))
            state.heavy[parent] = (int)vertex;
        if (state.height[vertex] + 1 > state.height[parent])
            state.height[parent] = state.height[vertex] + 1;
    }

    usz pool = 0;
    for (usz vertex = 0; vertex < n; vertex++) {
        if (vertex == 0 || state.heavy[state.parent[vertex]] != (int)vertex) {
            state.chain_base[vertex] = (int)pool;
            int current = (int)vertex;
            usz position = 0;
            while (current >= 0) {
                state.chain_head[current] = (int)vertex;
                state.chain_position[current] = (int)position;
                state.chain_nodes[pool + position] = current;
                current = state.heavy[current];
                position++;
            }
            current = state.parent[vertex];
            for (usz step = 0; step < position; step++) {
                state.head_ancestors[pool + step] = current;
                current = current >= 0 ? state.parent[current] : -1;
            }
            pool += position;
        }
    }
    for (usz vertex = 0; vertex < n; vertex++) state.up[vertex] = state.parent[vertex];
    for (usz level = 1; level < LOG_LEVELS; level++) {
        for (usz vertex = 0; vertex < n; vertex++) {
            int halfway = state.up[(level - 1) * MAX_N + vertex];
            state.up[level * MAX_N + vertex] = halfway >= 0 ?
                state.up[(level - 1) * MAX_N + (usz)halfway] : -1;
        }
    }
}

fn long long_chain_kth_ancestor(long* input, usz length, char* output,
    usz output_capacity) @export("long_chain_kth_ancestor") {
    if (input == null || length < 2 || length > 130) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > 64 || q_value < 1 || q_value > 32) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != n + 1 + 2*q) return -1;
    for (usz vertex = 1; vertex < n; vertex++)
        if (input[1+vertex] < 0 || input[1+vertex] >= (long)vertex) return -1;
    usz query_start = n + 1;
    for (usz query = 0; query < q; query++) {
        long vertex = input[query_start+2*query];
        long distance = input[query_start+2*query+1];
        if (vertex < 0 || vertex >= n_value || distance < 0 || distance >= 64) return -1;
    }
    usz required = 8*q;
    if (output == null || output_capacity < required) return -2;

    Long_Chain_Ancestor_State state = {};
    state.parent[0] = -1;
    for (usz vertex = 1; vertex < n; vertex++) state.parent[vertex] = (int)input[1+vertex];
    solve(&state, n);
    for (usz query = 0; query < q; query++) {
        usz vertex = (usz)input[query_start+2*query];
        usz distance = (usz)input[query_start+2*query+1];
        long answer = -1;
        if (distance <= (usz)state.depth[vertex]) {
            if (distance == 0) answer = (long)vertex;
            else {
                usz level = 0, value = distance;
                while (value > 1) { level++; value >>= 1; }
                usz jumped = (usz)state.up[level*MAX_N+vertex];
                usz remaining = distance - ((usz)1 << level);
                usz head = (usz)state.chain_head[jumped];
                usz position = (usz)state.chain_position[jumped];
                usz base = (usz)state.chain_base[head];
                if (remaining <= position) answer = state.chain_nodes[base+position-remaining];
                else {
                    usz steps = remaining-position;
                    if (steps <= (usz)state.height[head]) answer = state.head_ancestors[base+steps-1];
                }
            }
        }
        ulong bits = (ulong)answer;
        for (usz byte = 0; byte < 8; byte++) output[8*query+byte] = (char)(bits >> (8*byte));
    }
    return (long)required;
}
