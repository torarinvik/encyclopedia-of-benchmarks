module johnson_elementary_circuit_enumeration;

const usz MAX_VERTICES = 8;
const usz MAX_EDGES = 24;
const usz MAX_INPUT_LENGTH = 51;
const long COUNT_SCALE = 1000000000000l;

struct JohnsonState {
    usz n;
    usz start;
    usz depth;
    bool[64] edge;
    bool[8] inside;
    bool[8] blocked;
    bool[64] dependency;
    usz[8] path;
    long count;
    long code_sum;
}

struct SccState {
    usz n;
    usz lower_bound;
    usz next_index;
    usz component_count;
    usz stack_length;
    bool[64] edge;
    long[8] index;
    long[8] low_link;
    long[8] component_id;
    bool[8] on_stack;
    usz[8] stack;
    usz[8] component_size;
    usz[8] component_minimum;
}

fn void strong_connect(SccState* state, usz vertex) {
    state.index[vertex] = (long)state.next_index;
    state.low_link[vertex] = (long)state.next_index;
    state.next_index++;
    state.stack[state.stack_length] = vertex;
    state.stack_length++;
    state.on_stack[vertex] = true;

    for (usz neighbor = state.lower_bound; neighbor < state.n; neighbor++) {
        if (!state.edge[vertex * MAX_VERTICES + neighbor]) continue;
        if (state.index[neighbor] < 0) {
            strong_connect(state, neighbor);
            if (state.low_link[neighbor] < state.low_link[vertex])
                state.low_link[vertex] = state.low_link[neighbor];
        } else if (state.on_stack[neighbor] && state.index[neighbor] < state.low_link[vertex]) {
            state.low_link[vertex] = state.index[neighbor];
        }
    }

    if (state.low_link[vertex] != state.index[vertex]) return;
    usz component = state.component_count;
    usz size = 0;
    usz minimum = state.n;
    while (true) {
        state.stack_length--;
        usz member = state.stack[state.stack_length];
        state.on_stack[member] = false;
        state.component_id[member] = (long)component;
        size++;
        if (member < minimum) minimum = member;
        if (member == vertex) break;
    }
    state.component_size[component] = size;
    state.component_minimum[component] = minimum;
    state.component_count++;
}

fn void unblock(JohnsonState* state, usz vertex) {
    if (!state.blocked[vertex]) return;
    state.blocked[vertex] = false;
    for (usz dependent = 0; dependent < state.n; dependent++) {
        usz slot = vertex * MAX_VERTICES + dependent;
        if (state.dependency[slot]) {
            state.dependency[slot] = false;
            if (state.blocked[dependent]) unblock(state, dependent);
        }
    }
}

fn void record_cycle(JohnsonState* state) {
    long code = 0;
    long place = 1;
    for (usz i = 0; i < state.depth; i++) {
        code += (long)(state.path[i] + 1) * place;
        place *= 9;
    }
    state.count++;
    state.code_sum += code;
}

fn bool circuit(JohnsonState* state, usz vertex) {
    state.path[state.depth] = vertex;
    state.depth++;
    state.blocked[vertex] = true;
    bool found = false;
    for (usz neighbor = 0; neighbor < state.n; neighbor++) {
        usz edge_slot = vertex * MAX_VERTICES + neighbor;
        if (!state.inside[neighbor] || !state.edge[edge_slot]) continue;
        if (neighbor == state.start) {
            record_cycle(state);
            found = true;
        } else if (!state.blocked[neighbor] && circuit(state, neighbor)) {
            found = true;
        }
    }
    if (found) {
        unblock(state, vertex);
    } else {
        for (usz neighbor = 0; neighbor < state.n; neighbor++) {
            usz edge_slot = vertex * MAX_VERTICES + neighbor;
            if (state.inside[neighbor] && state.edge[edge_slot])
                state.dependency[neighbor * MAX_VERTICES + vertex] = true;
        }
    }
    state.depth--;
    return found;
}

fn long johnson_elementary_circuit_enumeration(long* input, usz length)
        @export("johnson_elementary_circuit_enumeration") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_VERTICES || input[1] < 0 || input[1] > (long)MAX_EDGES)
        return -1;
    usz n = (usz)input[0];
    usz m = (usz)input[1];
    if (length != 2 + 2 * m) return -1;

    bool[64] edge = {false};
    for (usz e = 0; e < m; e++) {
        long u_value = input[2 + 2 * e];
        long v_value = input[3 + 2 * e];
        if (u_value < 0 || u_value >= (long)n || v_value < 0 || v_value >= (long)n || u_value == v_value)
            return -1;
        usz slot = (usz)u_value * MAX_VERTICES + (usz)v_value;
        if (edge[slot]) return -1;
        edge[slot] = true;
    }

    long total_count = 0;
    long total_code_sum = 0;
    usz lower_bound = 0;
    while (lower_bound < n) {
        SccState scc = {};
        scc.n = n;
        scc.lower_bound = lower_bound;
        for (usz vertex = 0; vertex < MAX_VERTICES; vertex++) {
            scc.index[vertex] = -1;
            scc.component_id[vertex] = -1;
        }
        for (usz u = lower_bound; u < n; u++)
            for (usz v = lower_bound; v < n; v++)
                scc.edge[u * MAX_VERTICES + v] = edge[u * MAX_VERTICES + v];
        for (usz vertex = lower_bound; vertex < n; vertex++)
            if (scc.index[vertex] < 0) strong_connect(&scc, vertex);

        usz start = n;
        long selected_component = -1;
        for (usz component = 0; component < scc.component_count; component++)
            if (scc.component_size[component] > 1 && scc.component_minimum[component] < start) {
                start = scc.component_minimum[component];
                selected_component = (long)component;
            }
        if (selected_component < 0) break;

        JohnsonState state = {};
        state.n = n;
        state.start = start;
        for (usz u = lower_bound; u < n; u++) {
            state.inside[u] = scc.component_id[u] == selected_component;
            for (usz v = 0; v < n; v++) state.edge[u * MAX_VERTICES + v] = edge[u * MAX_VERTICES + v];
        }
        circuit(&state, start);
        total_count += state.count;
        total_code_sum += state.code_sum;
        lower_bound = start + 1;
    }
    return total_count * COUNT_SCALE + total_code_sum;
}
