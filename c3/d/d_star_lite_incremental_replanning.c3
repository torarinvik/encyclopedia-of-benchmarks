module d_star_lite_incremental_replanning;

const int MAX_VERTICES = 16;
const int MAX_EDGES = 48;
const int MAX_EVENTS = 16;
const usz MAX_PARSEABLE_LENGTH = 199;
const long INF_DISTANCE = 2305843009213693951;

struct DStarState {
    int vertex_count;
    int width;
    int edge_count;
    int start;
    int goal;
    int last_start;
    int open_count;
    int[48] edge_from;
    int[48] edge_to;
    int[48] edge_cost;
    int[16] open_vertices;
    bool[16] in_open;
    long[16] g;
    long[16] rhs;
    long[16] open_key1;
    long[16] open_key2;
    long km;
}

fn long manhattan(DStarState* state, int left, int right) {
    int left_row = left / state.width, right_row = right / state.width;
    int left_column = left % state.width, right_column = right % state.width;
    int row_distance = left_row > right_row ? left_row - right_row : right_row - left_row;
    int column_distance = left_column > right_column ? left_column - right_column : right_column - left_column;
    return (long)(row_distance + column_distance);
}

fn long key_first(DStarState* state, int vertex) {
    long best = state.g[vertex] < state.rhs[vertex] ? state.g[vertex] : state.rhs[vertex];
    return best + manhattan(state, state.start, vertex) + state.km;
}

fn long key_second(DStarState* state, int vertex) {
    return state.g[vertex] < state.rhs[vertex] ? state.g[vertex] : state.rhs[vertex];
}

fn bool pair_less(long left_first, long left_second, long right_first, long right_second) {
    return left_first < right_first || (left_first == right_first && left_second < right_second);
}

fn void remove_open(DStarState* state, int vertex) {
    if (!state.in_open[vertex]) return;
    for (int index = 0; index < state.open_count; index++) {
        if (state.open_vertices[index] != vertex) continue;
        for (int next = index + 1; next < state.open_count; next++)
            state.open_vertices[next - 1] = state.open_vertices[next];
        state.open_count -= 1;
        break;
    }
    state.in_open[vertex] = false;
}

fn void update_vertex(DStarState* state, int vertex) {
    if (vertex != state.goal) {
        long best = INF_DISTANCE;
        for (int edge = 0; edge < state.edge_count; edge++) {
            if (state.edge_from[edge] != vertex) continue;
            int target = state.edge_to[edge];
            long tail = state.g[target] >= INF_DISTANCE ? INF_DISTANCE : state.g[target] + state.edge_cost[edge];
            if (tail < best) best = tail;
        }
        state.rhs[vertex] = best;
    }

    remove_open(state, vertex);
    if (state.g[vertex] != state.rhs[vertex]) {
        state.open_key1[vertex] = key_first(state, vertex);
        state.open_key2[vertex] = key_second(state, vertex);
        state.open_vertices[state.open_count] = vertex;
        state.open_count += 1;
        state.in_open[vertex] = true;
    }
}

fn int smallest_open_index(DStarState* state) {
    int best_index = 0;
    for (int index = 1; index < state.open_count; index++) {
        int candidate = state.open_vertices[index], best = state.open_vertices[best_index];
        if (pair_less(state.open_key1[candidate], state.open_key2[candidate],
                      state.open_key1[best], state.open_key2[best]) ||
            (state.open_key1[candidate] == state.open_key1[best] &&
             state.open_key2[candidate] == state.open_key2[best] && candidate < best))
            best_index = index;
    }
    return best_index;
}

fn void compute_shortest_path(DStarState* state) {
    while (true) {
        if (state.open_count == 0) return;
        int top_index = smallest_open_index(state);
        int vertex = state.open_vertices[top_index];
        long old_first = state.open_key1[vertex], old_second = state.open_key2[vertex];
        long start_first = key_first(state, state.start), start_second = key_second(state, state.start);
        if (!pair_less(old_first, old_second, start_first, start_second) &&
            state.rhs[state.start] == state.g[state.start]) return;

        long new_first = key_first(state, vertex), new_second = key_second(state, vertex);
        if (pair_less(old_first, old_second, new_first, new_second)) {
            state.open_key1[vertex] = new_first;
            state.open_key2[vertex] = new_second;
            continue;
        }

        remove_open(state, vertex);
        if (state.g[vertex] > state.rhs[vertex]) {
            state.g[vertex] = state.rhs[vertex];
            for (int edge = 0; edge < state.edge_count; edge++)
                if (state.edge_to[edge] == vertex) update_vertex(state, state.edge_from[edge]);
        } else {
            state.g[vertex] = INF_DISTANCE;
            update_vertex(state, vertex);
            for (int edge = 0; edge < state.edge_count; edge++)
                if (state.edge_to[edge] == vertex) update_vertex(state, state.edge_from[edge]);
        }
    }
}

fn int next_vertex(DStarState* state) {
    if (state.start == state.goal || state.g[state.start] >= INF_DISTANCE) return 0;
    int best = MAX_VERTICES;
    for (int edge = 0; edge < state.edge_count; edge++) {
        if (state.edge_from[edge] != state.start) continue;
        int target = state.edge_to[edge];
        if (state.g[target] < INF_DISTANCE &&
            (long)state.edge_cost[edge] + state.g[target] == state.g[state.start] && target < best)
            best = target;
    }
    return best == MAX_VERTICES ? 0 : best + 1;
}

fn long d_star_lite_incremental_replanning(long* input, usz length)
    @export("d_star_lite_incremental_replanning") {
    if (input == null || length < 6 || length > MAX_PARSEABLE_LENGTH) return -1;

    long height_value = input[0], width_value = input[1];
    long edge_count_value = input[2], event_count_value = input[3];
    long start_value = input[4], goal_value = input[5];
    if (height_value < 1 || height_value > 4 || width_value < 1 || width_value > 4 ||
        height_value * width_value < 2 || height_value * width_value > MAX_VERTICES ||
        edge_count_value < 0 || event_count_value < 0 || event_count_value > MAX_EVENTS) return -1;

    int height = (int)height_value, width = (int)width_value;
    int vertex_count = height * width;
    int maximum_edges = 2 * (height * (width - 1) + width * (height - 1));
    if (edge_count_value > maximum_edges || start_value < 0 || start_value >= vertex_count ||
        goal_value < 0 || goal_value >= vertex_count ||
        length != 6 + 3 * (usz)edge_count_value + 3 * (usz)event_count_value) return -1;

    DStarState state = {};
    state.vertex_count = vertex_count;
    state.width = width;
    state.edge_count = (int)edge_count_value;
    state.start = (int)start_value;
    state.goal = (int)goal_value;
    state.last_start = state.start;

    bool[256] seen = zeroed;
    for (int edge = 0; edge < state.edge_count; edge++) {
        long from_value = input[6 + 3 * (usz)edge];
        long to_value = input[7 + 3 * (usz)edge];
        long cost_value = input[8 + 3 * (usz)edge];
        if (from_value < 0 || from_value >= vertex_count || to_value < 0 || to_value >= vertex_count ||
            cost_value < 1 || cost_value > 9) return -1;
        int from = (int)from_value, to = (int)to_value;
        int row_distance = from / width - to / width;
        int column_distance = from % width - to % width;
        if ((row_distance < 0 ? -row_distance : row_distance) +
                (column_distance < 0 ? -column_distance : column_distance) != 1 ||
            seen[from * MAX_VERTICES + to]) return -1;
        seen[from * MAX_VERTICES + to] = true;
        state.edge_from[edge] = from;
        state.edge_to[edge] = to;
        state.edge_cost[edge] = (int)cost_value;
    }

    int[MAX_EVENTS] event_start, event_edge, event_cost;
    usz event_offset = 6 + 3 * (usz)state.edge_count;
    for (int event = 0; event < (int)event_count_value; event++) {
        long new_start = input[event_offset + 3 * (usz)event];
        long edge_id = input[event_offset + 3 * (usz)event + 1];
        long new_cost = input[event_offset + 3 * (usz)event + 2];
        if (new_start < 0 || new_start >= vertex_count || edge_id < 0 || edge_id >= state.edge_count ||
            new_cost < 1 || new_cost > 9) return -1;
        event_start[event] = (int)new_start;
        event_edge[event] = (int)edge_id;
        event_cost[event] = (int)new_cost;
    }

    for (int vertex = 0; vertex < vertex_count; vertex++) {
        state.g[vertex] = INF_DISTANCE;
        state.rhs[vertex] = INF_DISTANCE;
    }
    state.rhs[state.goal] = 0;
    update_vertex(&state, state.goal);

    long result = 0;
    for (int event = 0; event < (int)event_count_value; event++) {
        state.km += manhattan(&state, state.last_start, event_start[event]);
        state.start = event_start[event];
        state.last_start = state.start;
        int edge = event_edge[event];
        state.edge_cost[edge] = event_cost[event];
        update_vertex(&state, state.edge_from[edge]);
        compute_shortest_path(&state);
        long distance_code = state.g[state.start] >= INF_DISTANCE ? 136 : state.g[state.start];
        int next_code = next_vertex(&state);
        result += (event + 1).long() * (distance_code + 1) * (next_code + 1);
    }
    return result;
}
