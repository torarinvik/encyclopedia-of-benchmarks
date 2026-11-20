module tree_subtree_distinct_sack;

const usz MAX_N = 64;
const usz MAX_COLORS = 256;
const usz MAX_INPUT_LENGTH = 130;

struct SackState {
    usz n;
    int[64] parent;
    int[64] first_child;
    int[64] next_sibling;
    usz[64] order;
    usz[64] tin;
    usz[64] subtree_size;
    int[64] heavy;
    usz[256] frequency;
    usz[64] answer;
    usz distinct;
    int[64] frame_vertex;
    int[64] frame_keep;
    int[64] frame_stage;
    int[64] frame_child;
}

fn void add_interval(SackState* state, usz begin, usz count, int* colors, int delta) {
    for (usz i = begin; i < begin + count; i++) {
        usz color = (usz)colors[state.order[i]];
        if (delta > 0) {
            if (state.frequency[color] == 0) state.distinct++;
            state.frequency[color]++;
        } else {
            state.frequency[color]--;
            if (state.frequency[color] == 0) state.distinct--;
        }
    }
}

fn void solve_sack(SackState* state, int* colors) {
    int[64] stack_next;
    int depth = 0;
    usz timer = 1;
    state.order[0] = 0;
    state.tin[0] = 0;
    stack_next[0] = state.first_child[0];
    while (depth >= 0) {
        int child = stack_next[depth];
        if (child >= 0) {
            stack_next[depth] = state.next_sibling[child];
            depth++;
            stack_next[depth] = state.first_child[child];
            state.tin[child] = timer;
            state.order[timer++] = (usz)child;
        } else {
            depth--;
        }
    }

    for (usz vertex = 0; vertex < state.n; vertex++) {
        state.subtree_size[vertex] = 1;
        state.heavy[vertex] = -1;
    }
    for (usz i = state.n; i > 1; i--) {
        int vertex = (int)state.order[i - 1];
        int parent = state.parent[vertex];
        state.subtree_size[parent] += state.subtree_size[vertex];
        int previous = state.heavy[parent];
        if (previous < 0 || state.subtree_size[vertex] > state.subtree_size[previous])
            state.heavy[parent] = vertex;
    }

    int top = 0;
    state.frame_vertex[0] = 0;
    state.frame_keep[0] = 0;
    state.frame_stage[0] = 0;
    state.frame_child[0] = state.first_child[0];
    while (top >= 0) {
        int vertex = state.frame_vertex[top];
        if (state.frame_stage[top] == 0) {
            int child = state.frame_child[top];
            while (child >= 0 && child == state.heavy[vertex])
                child = state.next_sibling[child];
            if (child >= 0) {
                state.frame_child[top] = state.next_sibling[child];
                top++;
                state.frame_vertex[top] = child;
                state.frame_keep[top] = 0;
                state.frame_stage[top] = 0;
                state.frame_child[top] = state.first_child[child];
            } else {
                state.frame_stage[top] = 1;
            }
        } else if (state.frame_stage[top] == 1) {
            state.frame_stage[top] = 2;
            int child = state.heavy[vertex];
            if (child >= 0) {
                top++;
                state.frame_vertex[top] = child;
                state.frame_keep[top] = 1;
                state.frame_stage[top] = 0;
                state.frame_child[top] = state.first_child[child];
            }
        } else {
            for (int child = state.first_child[vertex]; child >= 0; child = state.next_sibling[child]) {
                if (child != state.heavy[vertex])
                    add_interval(state, state.tin[child], state.subtree_size[child], colors, 1);
            }
            usz color = (usz)colors[vertex];
            if (state.frequency[color] == 0) state.distinct++;
            state.frequency[color]++;
            state.answer[vertex] = state.distinct;
            if (state.frame_keep[top] == 0)
                add_interval(state, state.tin[vertex], state.subtree_size[vertex], colors, -1);
            top--;
        }
    }
}

fn void write_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long tree_subtree_distinct_sack(long* input, usz length, char* output, usz output_capacity)
        @export("tree_subtree_distinct_sack") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > 64 || length != 2 * (usz)n_value) return -1;
    usz n = (usz)n_value;
    int[64] colors;
    for (usz vertex = 1; vertex < n; vertex++)
        if (input[vertex] < 0 || input[vertex] >= (long)vertex) return -1;
    for (usz vertex = 0; vertex < n; vertex++) {
        long color = input[n + vertex];
        if (color < 0 || color >= 256) return -1;
        colors[vertex] = (int)color;
    }
    usz required = 8 * n;
    if (output == null || output_capacity < required) return -2;

    SackState state = {};
    state.n = n;
    for (usz vertex = 0; vertex < n; vertex++) state.first_child[vertex] = -1;
    for (usz vertex = 1; vertex < n; vertex++) {
        int parent = (int)input[vertex];
        state.parent[vertex] = parent;
        state.next_sibling[vertex] = state.first_child[parent];
        state.first_child[parent] = (int)vertex;
    }
    solve_sack(&state, &colors[0]);
    for (usz vertex = 0; vertex < n; vertex++)
        write_i64(output, 8 * vertex, (long)state.answer[vertex]);
    return (long)required;
}
