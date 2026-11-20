#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_vertices = 16;
constexpr int max_edges = 48;
constexpr int max_events = 16;
constexpr std::size_t max_parseable_length = 199;
constexpr std::int64_t inf_distance = INT64_C(2305843009213693951);

struct DStarState {
    int vertex_count = 0;
    int width = 0;
    int edge_count = 0;
    int start = 0;
    int goal = 0;
    int last_start = 0;
    int open_count = 0;
    std::array<int, max_edges> edge_from{};
    std::array<int, max_edges> edge_to{};
    std::array<int, max_edges> edge_cost{};
    std::array<int, max_vertices> open_vertices{};
    std::array<bool, max_vertices> in_open{};
    std::array<std::int64_t, max_vertices> g{};
    std::array<std::int64_t, max_vertices> rhs{};
    std::array<std::int64_t, max_vertices> open_key1{};
    std::array<std::int64_t, max_vertices> open_key2{};
    std::int64_t km = 0;
};

std::int64_t manhattan(const DStarState& state, int left, int right) noexcept {
    const int left_row = left / state.width;
    const int right_row = right / state.width;
    const int left_column = left % state.width;
    const int right_column = right % state.width;
    const int row_distance = left_row > right_row ? left_row - right_row : right_row - left_row;
    const int column_distance = left_column > right_column
                                    ? left_column - right_column
                                    : right_column - left_column;
    return row_distance + column_distance;
}

std::int64_t key_first(const DStarState& state, int vertex) noexcept {
    const auto best = state.g[vertex] < state.rhs[vertex] ? state.g[vertex] : state.rhs[vertex];
    return best + manhattan(state, state.start, vertex) + state.km;
}

std::int64_t key_second(const DStarState& state, int vertex) noexcept {
    return state.g[vertex] < state.rhs[vertex] ? state.g[vertex] : state.rhs[vertex];
}

bool pair_less(std::int64_t left_first, std::int64_t left_second,
               std::int64_t right_first, std::int64_t right_second) noexcept {
    return left_first < right_first || (left_first == right_first && left_second < right_second);
}

void remove_open(DStarState& state, int vertex) noexcept {
    if (!state.in_open[vertex]) return;
    for (int index = 0; index < state.open_count; ++index) {
        if (state.open_vertices[index] != vertex) continue;
        for (int next = index + 1; next < state.open_count; ++next)
            state.open_vertices[next - 1] = state.open_vertices[next];
        --state.open_count;
        break;
    }
    state.in_open[vertex] = false;
}

void update_vertex(DStarState& state, int vertex) noexcept {
    if (vertex != state.goal) {
        auto best = inf_distance;
        for (int edge = 0; edge < state.edge_count; ++edge) {
            if (state.edge_from[edge] != vertex) continue;
            const int target = state.edge_to[edge];
            const auto tail = state.g[target] >= inf_distance
                                  ? inf_distance
                                  : state.g[target] + state.edge_cost[edge];
            if (tail < best) best = tail;
        }
        state.rhs[vertex] = best;
    }

    remove_open(state, vertex);
    if (state.g[vertex] != state.rhs[vertex]) {
        state.open_key1[vertex] = key_first(state, vertex);
        state.open_key2[vertex] = key_second(state, vertex);
        state.open_vertices[state.open_count++] = vertex;
        state.in_open[vertex] = true;
    }
}

int smallest_open_index(const DStarState& state) noexcept {
    int best_index = 0;
    for (int index = 1; index < state.open_count; ++index) {
        const int candidate = state.open_vertices[index];
        const int best = state.open_vertices[best_index];
        if (pair_less(state.open_key1[candidate], state.open_key2[candidate],
                      state.open_key1[best], state.open_key2[best]) ||
            (state.open_key1[candidate] == state.open_key1[best] &&
             state.open_key2[candidate] == state.open_key2[best] && candidate < best))
            best_index = index;
    }
    return best_index;
}

void compute_shortest_path(DStarState& state) noexcept {
    for (;;) {
        if (state.open_count == 0) return;
        const int top_index = smallest_open_index(state);
        const int vertex = state.open_vertices[top_index];
        const auto old_first = state.open_key1[vertex];
        const auto old_second = state.open_key2[vertex];
        const auto start_first = key_first(state, state.start);
        const auto start_second = key_second(state, state.start);
        if (!pair_less(old_first, old_second, start_first, start_second) &&
            state.rhs[state.start] == state.g[state.start]) return;

        const auto new_first = key_first(state, vertex);
        const auto new_second = key_second(state, vertex);
        if (pair_less(old_first, old_second, new_first, new_second)) {
            state.open_key1[vertex] = new_first;
            state.open_key2[vertex] = new_second;
            continue;
        }

        remove_open(state, vertex);
        if (state.g[vertex] > state.rhs[vertex]) {
            state.g[vertex] = state.rhs[vertex];
            for (int edge = 0; edge < state.edge_count; ++edge)
                if (state.edge_to[edge] == vertex) update_vertex(state, state.edge_from[edge]);
        } else {
            state.g[vertex] = inf_distance;
            update_vertex(state, vertex);
            for (int edge = 0; edge < state.edge_count; ++edge)
                if (state.edge_to[edge] == vertex) update_vertex(state, state.edge_from[edge]);
        }
    }
}

int next_vertex(const DStarState& state) noexcept {
    if (state.start == state.goal || state.g[state.start] >= inf_distance) return 0;
    int best = max_vertices;
    for (int edge = 0; edge < state.edge_count; ++edge) {
        if (state.edge_from[edge] != state.start) continue;
        const int target = state.edge_to[edge];
        if (state.g[target] < inf_distance &&
            state.edge_cost[edge] + state.g[target] == state.g[state.start] && target < best)
            best = target;
    }
    return best == max_vertices ? 0 : best + 1;
}
}

extern "C" std::int64_t d_star_lite_incremental_replanning(const std::int64_t* input,
                                                            std::size_t length) noexcept {
    if (input == nullptr || length < 6 || length > max_parseable_length) return -1;

    const auto height_value = input[0];
    const auto width_value = input[1];
    const auto edge_count_value = input[2];
    const auto event_count_value = input[3];
    const auto start_value = input[4];
    const auto goal_value = input[5];
    if (height_value < 1 || height_value > 4 || width_value < 1 || width_value > 4 ||
        height_value * width_value < 2 || height_value * width_value > max_vertices ||
        edge_count_value < 0 || event_count_value < 0 || event_count_value > max_events) return -1;

    const int height = static_cast<int>(height_value);
    const int width = static_cast<int>(width_value);
    const int vertex_count = height * width;
    const int maximum_edges = 2 * (height * (width - 1) + width * (height - 1));
    if (edge_count_value > maximum_edges || start_value < 0 || start_value >= vertex_count ||
        goal_value < 0 || goal_value >= vertex_count ||
        length != 6 + 3 * static_cast<std::size_t>(edge_count_value) +
                      3 * static_cast<std::size_t>(event_count_value)) return -1;

    DStarState state{};
    state.vertex_count = vertex_count;
    state.width = width;
    state.edge_count = static_cast<int>(edge_count_value);
    state.start = static_cast<int>(start_value);
    state.goal = static_cast<int>(goal_value);
    state.last_start = state.start;

    std::array<std::array<bool, max_vertices>, max_vertices> seen{};
    for (int edge = 0; edge < state.edge_count; ++edge) {
        const auto from_value = input[6 + 3 * static_cast<std::size_t>(edge)];
        const auto to_value = input[7 + 3 * static_cast<std::size_t>(edge)];
        const auto cost_value = input[8 + 3 * static_cast<std::size_t>(edge)];
        if (from_value < 0 || from_value >= vertex_count || to_value < 0 || to_value >= vertex_count ||
            cost_value < 1 || cost_value > 9) return -1;
        const int from = static_cast<int>(from_value);
        const int to = static_cast<int>(to_value);
        const int row_distance = from / width - to / width;
        const int column_distance = from % width - to % width;
        if ((row_distance < 0 ? -row_distance : row_distance) +
                (column_distance < 0 ? -column_distance : column_distance) != 1 ||
            seen[from][to]) return -1;
        seen[from][to] = true;
        state.edge_from[edge] = from;
        state.edge_to[edge] = to;
        state.edge_cost[edge] = static_cast<int>(cost_value);
    }

    std::array<int, max_events> event_start{};
    std::array<int, max_events> event_edge{};
    std::array<int, max_events> event_cost{};
    const auto event_offset = 6 + 3 * static_cast<std::size_t>(state.edge_count);
    for (int event = 0; event < static_cast<int>(event_count_value); ++event) {
        const auto new_start = input[event_offset + 3 * static_cast<std::size_t>(event)];
        const auto edge_id = input[event_offset + 3 * static_cast<std::size_t>(event) + 1];
        const auto new_cost = input[event_offset + 3 * static_cast<std::size_t>(event) + 2];
        if (new_start < 0 || new_start >= vertex_count || edge_id < 0 ||
            edge_id >= state.edge_count || new_cost < 1 || new_cost > 9) return -1;
        event_start[event] = static_cast<int>(new_start);
        event_edge[event] = static_cast<int>(edge_id);
        event_cost[event] = static_cast<int>(new_cost);
    }

    for (int vertex = 0; vertex < vertex_count; ++vertex)
        state.g[vertex] = state.rhs[vertex] = inf_distance;
    state.rhs[state.goal] = 0;
    update_vertex(state, state.goal);

    std::int64_t result = 0;
    for (int event = 0; event < static_cast<int>(event_count_value); ++event) {
        state.km += manhattan(state, state.last_start, event_start[event]);
        state.start = event_start[event];
        state.last_start = state.start;
        const int edge = event_edge[event];
        state.edge_cost[edge] = event_cost[event];
        update_vertex(state, state.edge_from[edge]);
        compute_shortest_path(state);
        const auto distance_code = state.g[state.start] >= inf_distance ? 136 : state.g[state.start];
        const int next_code = next_vertex(state);
        result += static_cast<std::int64_t>(event + 1) * (distance_code + 1) * (next_code + 1);
    }
    return result;
}
