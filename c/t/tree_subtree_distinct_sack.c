/* DSU-on-tree distinct-color counts for all rooted subtrees. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_COLORS = 256, MAX_INPUT_LENGTH = 130 };

typedef struct {
    size_t n;
    int parent[MAX_N], first_child[MAX_N], next_sibling[MAX_N];
    size_t order[MAX_N], tin[MAX_N], subtree_size[MAX_N];
    int heavy[MAX_N];
    size_t frequency[MAX_COLORS], answer[MAX_N], distinct;
    int frame_vertex[MAX_N], frame_keep[MAX_N], frame_stage[MAX_N];
    int frame_child[MAX_N];
} SackState;

static void add_interval(SackState *state, size_t begin, size_t count,
                         const int *colors, int delta) {
    for (size_t i = begin; i < begin + count; ++i) {
        size_t color = (size_t)colors[state->order[i]];
        if (delta > 0) {
            if (state->frequency[color] == 0) ++state->distinct;
            ++state->frequency[color];
        } else {
            --state->frequency[color];
            if (state->frequency[color] == 0) --state->distinct;
        }
    }
}

static void solve_sack(SackState *state, const int *colors) {
    int stack_next[MAX_N];
    int depth = 0;
    size_t timer = 1;
    state->order[0] = 0;
    state->tin[0] = 0;
    stack_next[0] = state->first_child[0];
    while (depth >= 0) {
        int child = stack_next[depth];
        if (child >= 0) {
            stack_next[depth] = state->next_sibling[child];
            ++depth;
            stack_next[depth] = state->first_child[child];
            state->tin[child] = timer;
            state->order[timer++] = (size_t)child;
        } else {
            --depth;
        }
    }

    for (size_t vertex = 0; vertex < state->n; ++vertex) {
        state->subtree_size[vertex] = 1;
        state->heavy[vertex] = -1;
    }
    for (size_t i = state->n; i > 1; --i) {
        int vertex = (int)state->order[i - 1];
        int parent = state->parent[vertex];
        state->subtree_size[parent] += state->subtree_size[vertex];
        int previous = state->heavy[parent];
        if (previous < 0 || state->subtree_size[vertex] > state->subtree_size[previous])
            state->heavy[parent] = vertex;
    }

    int top = 0;
    state->frame_vertex[0] = 0;
    state->frame_keep[0] = 0;
    state->frame_stage[0] = 0;
    state->frame_child[0] = state->first_child[0];
    while (top >= 0) {
        int vertex = state->frame_vertex[top];
        if (state->frame_stage[top] == 0) {
            int child = state->frame_child[top];
            while (child >= 0 && child == state->heavy[vertex])
                child = state->next_sibling[child];
            if (child >= 0) {
                state->frame_child[top] = state->next_sibling[child];
                ++top;
                state->frame_vertex[top] = child;
                state->frame_keep[top] = 0;
                state->frame_stage[top] = 0;
                state->frame_child[top] = state->first_child[child];
            } else {
                state->frame_stage[top] = 1;
            }
        } else if (state->frame_stage[top] == 1) {
            state->frame_stage[top] = 2;
            int child = state->heavy[vertex];
            if (child >= 0) {
                ++top;
                state->frame_vertex[top] = child;
                state->frame_keep[top] = 1;
                state->frame_stage[top] = 0;
                state->frame_child[top] = state->first_child[child];
            }
        } else {
            for (int child = state->first_child[vertex]; child >= 0;
                 child = state->next_sibling[child]) {
                if (child != state->heavy[vertex])
                    add_interval(state, state->tin[child], state->subtree_size[child], colors, 1);
            }
            size_t color = (size_t)colors[vertex];
            if (state->frequency[color] == 0) ++state->distinct;
            ++state->frequency[color];
            state->answer[vertex] = state->distinct;
            if (!state->frame_keep[top])
                add_interval(state, state->tin[vertex], state->subtree_size[vertex], colors, -1);
            --top;
        }
    }
}

static void write_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t tree_subtree_distinct_sack(const int64_t *input, size_t length,
                                   uint8_t *output, size_t output_capacity) {
    if (!input || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N || length != 2 * (size_t)n_value) return -1;
    size_t n = (size_t)n_value;
    int colors[MAX_N];
    for (size_t vertex = 1; vertex < n; ++vertex)
        if (input[vertex] < 0 || input[vertex] >= (int64_t)vertex) return -1;
    for (size_t vertex = 0; vertex < n; ++vertex) {
        int64_t color = input[n + vertex];
        if (color < 0 || color >= MAX_COLORS) return -1;
        colors[vertex] = (int)color;
    }
    size_t required = 8 * n;
    if (!output || output_capacity < required) return -2;

    SackState state = {0};
    state.n = n;
    for (size_t vertex = 0; vertex < n; ++vertex) state.first_child[vertex] = -1;
    for (size_t vertex = 1; vertex < n; ++vertex) {
        int parent = (int)input[vertex];
        state.parent[vertex] = parent;
        state.next_sibling[vertex] = state.first_child[parent];
        state.first_child[parent] = (int)vertex;
    }
    solve_sack(&state, colors);
    for (size_t vertex = 0; vertex < n; ++vertex)
        write_i64(output, 8 * vertex, (int64_t)state.answer[vertex]);
    return (int64_t)required;
}
