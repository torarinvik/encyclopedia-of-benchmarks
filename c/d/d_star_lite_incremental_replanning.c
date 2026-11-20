#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 16
#define MAX_EDGES 48
#define MAX_EVENTS 16
#define MAX_PARSEABLE_LENGTH 199
#define INF_DISTANCE INT64_C(2305843009213693951)

typedef struct {
    int vertex_count;
    int width;
    int edge_count;
    int start;
    int goal;
    int last_start;
    int open_count;
    int edge_from[MAX_EDGES];
    int edge_to[MAX_EDGES];
    int edge_cost[MAX_EDGES];
    int open_vertices[MAX_VERTICES];
    unsigned char in_open[MAX_VERTICES];
    int64_t g[MAX_VERTICES];
    int64_t rhs[MAX_VERTICES];
    int64_t open_key1[MAX_VERTICES];
    int64_t open_key2[MAX_VERTICES];
    int64_t km;
} DStarState;

static int64_t manhattan(const DStarState *state, int left, int right) {
    const int left_row = left / state->width;
    const int right_row = right / state->width;
    const int left_column = left % state->width;
    const int right_column = right % state->width;
    const int row_distance = left_row > right_row ? left_row - right_row : right_row - left_row;
    const int column_distance = left_column > right_column
                                    ? left_column - right_column
                                    : right_column - left_column;
    return row_distance + column_distance;
}

static int64_t key_first(const DStarState *state, int vertex) {
    const int64_t best = state->g[vertex] < state->rhs[vertex]
                             ? state->g[vertex]
                             : state->rhs[vertex];
    return best + manhattan(state, state->start, vertex) + state->km;
}

static int64_t key_second(const DStarState *state, int vertex) {
    return state->g[vertex] < state->rhs[vertex]
               ? state->g[vertex]
               : state->rhs[vertex];
}

static int pair_less(int64_t left_first, int64_t left_second,
                     int64_t right_first, int64_t right_second) {
    return left_first < right_first ||
           (left_first == right_first && left_second < right_second);
}

static void remove_open(DStarState *state, int vertex) {
    if (!state->in_open[vertex]) return;
    for (int index = 0; index < state->open_count; ++index) {
        if (state->open_vertices[index] != vertex) continue;
        for (int next = index + 1; next < state->open_count; ++next)
            state->open_vertices[next - 1] = state->open_vertices[next];
        --state->open_count;
        break;
    }
    state->in_open[vertex] = 0;
}

static void update_vertex(DStarState *state, int vertex) {
    if (vertex != state->goal) {
        int64_t best = INF_DISTANCE;
        for (int edge = 0; edge < state->edge_count; ++edge) {
            if (state->edge_from[edge] != vertex) continue;
            const int target = state->edge_to[edge];
            const int64_t tail = state->g[target] >= INF_DISTANCE
                                     ? INF_DISTANCE
                                     : state->g[target] + state->edge_cost[edge];
            if (tail < best) best = tail;
        }
        state->rhs[vertex] = best;
    }

    remove_open(state, vertex);
    if (state->g[vertex] != state->rhs[vertex]) {
        state->open_key1[vertex] = key_first(state, vertex);
        state->open_key2[vertex] = key_second(state, vertex);
        state->open_vertices[state->open_count++] = vertex;
        state->in_open[vertex] = 1;
    }
}

static int smallest_open_index(const DStarState *state) {
    int best_index = 0;
    for (int index = 1; index < state->open_count; ++index) {
        const int candidate = state->open_vertices[index];
        const int best = state->open_vertices[best_index];
        if (pair_less(state->open_key1[candidate], state->open_key2[candidate],
                      state->open_key1[best], state->open_key2[best]) ||
            (state->open_key1[candidate] == state->open_key1[best] &&
             state->open_key2[candidate] == state->open_key2[best] && candidate < best))
            best_index = index;
    }
    return best_index;
}

static void compute_shortest_path(DStarState *state) {
    for (;;) {
        if (state->open_count == 0) return;
        const int top_index = smallest_open_index(state);
        const int vertex = state->open_vertices[top_index];
        const int64_t old_first = state->open_key1[vertex];
        const int64_t old_second = state->open_key2[vertex];
        const int64_t start_first = key_first(state, state->start);
        const int64_t start_second = key_second(state, state->start);
        if (!pair_less(old_first, old_second, start_first, start_second) &&
            state->rhs[state->start] == state->g[state->start]) return;

        const int64_t new_first = key_first(state, vertex);
        const int64_t new_second = key_second(state, vertex);
        if (pair_less(old_first, old_second, new_first, new_second)) {
            state->open_key1[vertex] = new_first;
            state->open_key2[vertex] = new_second;
            continue;
        }

        remove_open(state, vertex);
        if (state->g[vertex] > state->rhs[vertex]) {
            state->g[vertex] = state->rhs[vertex];
            for (int edge = 0; edge < state->edge_count; ++edge)
                if (state->edge_to[edge] == vertex) update_vertex(state, state->edge_from[edge]);
        } else {
            state->g[vertex] = INF_DISTANCE;
            update_vertex(state, vertex);
            for (int edge = 0; edge < state->edge_count; ++edge)
                if (state->edge_to[edge] == vertex) update_vertex(state, state->edge_from[edge]);
        }
    }
}

static int next_vertex(const DStarState *state) {
    if (state->start == state->goal || state->g[state->start] >= INF_DISTANCE) return 0;
    int best = MAX_VERTICES;
    for (int edge = 0; edge < state->edge_count; ++edge) {
        if (state->edge_from[edge] != state->start) continue;
        const int target = state->edge_to[edge];
        if (state->g[target] < INF_DISTANCE &&
            state->edge_cost[edge] + state->g[target] == state->g[state->start] && target < best)
            best = target;
    }
    return best == MAX_VERTICES ? 0 : best + 1;
}

int64_t d_star_lite_incremental_replanning(const int64_t *input, size_t length) {
    if (input == NULL || length < 6u || length > MAX_PARSEABLE_LENGTH) return -1;

    const int64_t height_value = input[0];
    const int64_t width_value = input[1];
    const int64_t edge_count_value = input[2];
    const int64_t event_count_value = input[3];
    const int64_t start_value = input[4];
    const int64_t goal_value = input[5];
    if (height_value < 1 || height_value > 4 || width_value < 1 || width_value > 4 ||
        height_value * width_value < 2 || height_value * width_value > MAX_VERTICES ||
        edge_count_value < 0 || event_count_value < 0 || event_count_value > MAX_EVENTS)
        return -1;

    const int height = (int)height_value;
    const int width = (int)width_value;
    const int vertex_count = height * width;
    const int maximum_edges = 2 * (height * (width - 1) + width * (height - 1));
    if (edge_count_value > maximum_edges || start_value < 0 || start_value >= vertex_count ||
        goal_value < 0 || goal_value >= vertex_count ||
        length != 6u + 3u * (size_t)edge_count_value + 3u * (size_t)event_count_value)
        return -1;

    DStarState state = {0};
    state.vertex_count = vertex_count;
    state.width = width;
    state.edge_count = (int)edge_count_value;
    state.start = (int)start_value;
    state.goal = (int)goal_value;
    state.last_start = state.start;

    unsigned char seen[MAX_VERTICES][MAX_VERTICES] = {{0}};
    for (int edge = 0; edge < state.edge_count; ++edge) {
        const int64_t from_value = input[6u + 3u * (size_t)edge];
        const int64_t to_value = input[7u + 3u * (size_t)edge];
        const int64_t cost_value = input[8u + 3u * (size_t)edge];
        if (from_value < 0 || from_value >= vertex_count || to_value < 0 || to_value >= vertex_count ||
            cost_value < 1 || cost_value > 9) return -1;
        const int from = (int)from_value;
        const int to = (int)to_value;
        const int row_distance = from / width - to / width;
        const int column_distance = from % width - to % width;
        if ((row_distance < 0 ? -row_distance : row_distance) +
                (column_distance < 0 ? -column_distance : column_distance) != 1 ||
            seen[from][to]) return -1;
        seen[from][to] = 1;
        state.edge_from[edge] = from;
        state.edge_to[edge] = to;
        state.edge_cost[edge] = (int)cost_value;
    }

    int event_start[MAX_EVENTS];
    int event_edge[MAX_EVENTS];
    int event_cost[MAX_EVENTS];
    const size_t event_offset = 6u + 3u * (size_t)state.edge_count;
    for (int event = 0; event < (int)event_count_value; ++event) {
        const int64_t new_start = input[event_offset + 3u * (size_t)event];
        const int64_t edge_id = input[event_offset + 3u * (size_t)event + 1u];
        const int64_t new_cost = input[event_offset + 3u * (size_t)event + 2u];
        if (new_start < 0 || new_start >= vertex_count || edge_id < 0 ||
            edge_id >= state.edge_count || new_cost < 1 || new_cost > 9) return -1;
        event_start[event] = (int)new_start;
        event_edge[event] = (int)edge_id;
        event_cost[event] = (int)new_cost;
    }

    for (int vertex = 0; vertex < vertex_count; ++vertex)
        state.g[vertex] = state.rhs[vertex] = INF_DISTANCE;
    state.rhs[state.goal] = 0;
    update_vertex(&state, state.goal);

    int64_t result = 0;
    for (int event = 0; event < (int)event_count_value; ++event) {
        state.km += manhattan(&state, state.last_start, event_start[event]);
        state.start = event_start[event];
        state.last_start = state.start;
        state.edge_cost[event_edge[event]] = event_cost[event];
        update_vertex(&state, state.edge_from[event_edge[event]]);
        compute_shortest_path(&state);

        const int64_t distance_code = state.g[state.start] >= INF_DISTANCE
                                          ? 136
                                          : state.g[state.start];
        const int next_code = next_vertex(&state);
        result += (int64_t)(event + 1) * (distance_code + 1) * (next_code + 1);
    }
    return result;
}
