#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 8
#define MAX_EDGES 24
#define MAX_INPUT_LENGTH 51
#define COUNT_SCALE INT64_C(1000000000000)

typedef struct {
    bool edge[MAX_VERTICES * MAX_VERTICES];
    bool inside[MAX_VERTICES];
    bool blocked[MAX_VERTICES];
    bool dependency[MAX_VERTICES * MAX_VERTICES];
    size_t path[MAX_VERTICES];
    size_t n, start, depth;
    int64_t count, code_sum;
} JohnsonState;

typedef struct {
    const bool *edge;
    size_t n, lower_bound, next_index, component_count, stack_length;
    int index[MAX_VERTICES], low_link[MAX_VERTICES], component_id[MAX_VERTICES];
    bool on_stack[MAX_VERTICES];
    size_t stack[MAX_VERTICES], component_size[MAX_VERTICES], component_minimum[MAX_VERTICES];
} SccState;

static void strong_connect(SccState *state, size_t vertex)
{
    state->index[vertex] = (int)state->next_index;
    state->low_link[vertex] = (int)state->next_index;
    ++state->next_index;
    state->stack[state->stack_length++] = vertex;
    state->on_stack[vertex] = true;

    for (size_t neighbor = state->lower_bound; neighbor < state->n; ++neighbor) {
        if (!state->edge[vertex * MAX_VERTICES + neighbor]) continue;
        if (state->index[neighbor] < 0) {
            strong_connect(state, neighbor);
            if (state->low_link[neighbor] < state->low_link[vertex])
                state->low_link[vertex] = state->low_link[neighbor];
        } else if (state->on_stack[neighbor] && state->index[neighbor] < state->low_link[vertex]) {
            state->low_link[vertex] = state->index[neighbor];
        }
    }

    if (state->low_link[vertex] != state->index[vertex]) return;
    const size_t component = state->component_count;
    size_t size = 0, minimum = state->n;
    while (true) {
        const size_t member = state->stack[--state->stack_length];
        state->on_stack[member] = false;
        state->component_id[member] = (int)component;
        ++size;
        if (member < minimum) minimum = member;
        if (member == vertex) break;
    }
    state->component_size[component] = size;
    state->component_minimum[component] = minimum;
    ++state->component_count;
}

static void unblock(JohnsonState *state, size_t vertex)
{
    if (!state->blocked[vertex]) return;
    state->blocked[vertex] = false;
    for (size_t dependent = 0; dependent < state->n; ++dependent) {
        const size_t slot = vertex * MAX_VERTICES + dependent;
        if (state->dependency[slot]) {
            state->dependency[slot] = false;
            if (state->blocked[dependent]) unblock(state, dependent);
        }
    }
}

static void record_cycle(JohnsonState *state)
{
    int64_t code = 0, place = 1;
    for (size_t i = 0; i < state->depth; ++i) {
        code += (int64_t)(state->path[i] + 1) * place;
        place *= 9;
    }
    ++state->count;
    state->code_sum += code;
}

static bool circuit(JohnsonState *state, size_t vertex)
{
    state->path[state->depth++] = vertex;
    state->blocked[vertex] = true;
    bool found = false;
    for (size_t neighbor = 0; neighbor < state->n; ++neighbor) {
        if (!state->inside[neighbor] || !state->edge[vertex * MAX_VERTICES + neighbor]) continue;
        if (neighbor == state->start) {
            record_cycle(state);
            found = true;
        } else if (!state->blocked[neighbor] && circuit(state, neighbor)) {
            found = true;
        }
    }
    if (found) {
        unblock(state, vertex);
    } else {
        for (size_t neighbor = 0; neighbor < state->n; ++neighbor)
            if (state->inside[neighbor] && state->edge[vertex * MAX_VERTICES + neighbor])
                state->dependency[neighbor * MAX_VERTICES + vertex] = true;
    }
    --state->depth;
    return found;
}

int64_t johnson_elementary_circuit_enumeration(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES) return -1;
    const size_t n = (size_t)input[0], m = (size_t)input[1];
    if (length != 2 + 2 * m) return -1;

    bool edge[MAX_VERTICES * MAX_VERTICES] = {false};
    for (size_t e = 0; e < m; ++e) {
        const int64_t u_value = input[2 + 2 * e], v_value = input[3 + 2 * e];
        if (u_value < 0 || u_value >= (int64_t)n || v_value < 0 || v_value >= (int64_t)n || u_value == v_value)
            return -1;
        const size_t slot = (size_t)u_value * MAX_VERTICES + (size_t)v_value;
        if (edge[slot]) return -1;
        edge[slot] = true;
    }

    int64_t total_count = 0, total_code_sum = 0;
    size_t lower_bound = 0;
    while (lower_bound < n) {
        SccState scc = {0};
        scc.edge = edge;
        scc.n = n;
        scc.lower_bound = lower_bound;
        for (size_t vertex = 0; vertex < MAX_VERTICES; ++vertex) {
            scc.index[vertex] = -1;
            scc.component_id[vertex] = -1;
        }
        for (size_t vertex = lower_bound; vertex < n; ++vertex)
            if (scc.index[vertex] < 0) strong_connect(&scc, vertex);

        size_t start = n;
        int selected_component = -1;
        for (size_t component = 0; component < scc.component_count; ++component)
            if (scc.component_size[component] > 1 && scc.component_minimum[component] < start) {
                start = scc.component_minimum[component];
                selected_component = (int)component;
            }
        if (selected_component < 0) break;

        JohnsonState state = {0};
        state.n = n;
        state.start = start;
        for (size_t u = lower_bound; u < n; ++u) {
            state.inside[u] = scc.component_id[u] == selected_component;
            for (size_t v = 0; v < n; ++v) state.edge[u * MAX_VERTICES + v] = edge[u * MAX_VERTICES + v];
        }
        (void)circuit(&state, start);
        total_count += state.count;
        total_code_sum += state.code_sum;
        lower_bound = start + 1;
    }
    return total_count * COUNT_SCALE + total_code_sum;
}
