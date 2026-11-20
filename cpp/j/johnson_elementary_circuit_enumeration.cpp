#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxVertices = 8;
constexpr std::size_t MaxEdges = 24;
constexpr std::size_t MaxInputLength = 51;
constexpr std::int64_t CountScale = INT64_C(1000000000000);

struct JohnsonState {
    std::array<bool, MaxVertices * MaxVertices> edge{};
    std::array<bool, MaxVertices> inside{};
    std::array<bool, MaxVertices> blocked{};
    std::array<bool, MaxVertices * MaxVertices> dependency{};
    std::array<std::size_t, MaxVertices> path{};
    std::size_t n = 0, start = 0, depth = 0;
    std::int64_t count = 0, code_sum = 0;
};

struct SccState {
    std::array<bool, MaxVertices * MaxVertices> edge{};
    std::size_t n = 0, lower_bound = 0, next_index = 0, component_count = 0, stack_length = 0;
    std::array<int, MaxVertices> index{}, low_link{}, component_id{};
    std::array<bool, MaxVertices> on_stack{};
    std::array<std::size_t, MaxVertices> stack{}, component_size{}, component_minimum{};
};

void strong_connect(std::size_t vertex, SccState &state)
{
    state.index[vertex] = static_cast<int>(state.next_index);
    state.low_link[vertex] = static_cast<int>(state.next_index);
    ++state.next_index;
    state.stack[state.stack_length++] = vertex;
    state.on_stack[vertex] = true;

    for (std::size_t neighbor = state.lower_bound; neighbor < state.n; ++neighbor) {
        if (!state.edge[vertex * MaxVertices + neighbor]) continue;
        if (state.index[neighbor] < 0) {
            strong_connect(neighbor, state);
            if (state.low_link[neighbor] < state.low_link[vertex])
                state.low_link[vertex] = state.low_link[neighbor];
        } else if (state.on_stack[neighbor] && state.index[neighbor] < state.low_link[vertex]) {
            state.low_link[vertex] = state.index[neighbor];
        }
    }

    if (state.low_link[vertex] != state.index[vertex]) return;
    const std::size_t component = state.component_count;
    std::size_t size = 0, minimum = state.n;
    while (true) {
        const std::size_t member = state.stack[--state.stack_length];
        state.on_stack[member] = false;
        state.component_id[member] = static_cast<int>(component);
        ++size;
        if (member < minimum) minimum = member;
        if (member == vertex) break;
    }
    state.component_size[component] = size;
    state.component_minimum[component] = minimum;
    ++state.component_count;
}

void unblock(JohnsonState &state, std::size_t vertex)
{
    if (!state.blocked[vertex]) return;
    state.blocked[vertex] = false;
    for (std::size_t dependent = 0; dependent < state.n; ++dependent) {
        const auto slot = vertex * MaxVertices + dependent;
        if (state.dependency[slot]) {
            state.dependency[slot] = false;
            if (state.blocked[dependent]) unblock(state, dependent);
        }
    }
}

void record_cycle(JohnsonState &state)
{
    std::int64_t code = 0, place = 1;
    for (std::size_t i = 0; i < state.depth; ++i) {
        code += static_cast<std::int64_t>(state.path[i] + 1) * place;
        place *= 9;
    }
    ++state.count;
    state.code_sum += code;
}

bool circuit(JohnsonState &state, std::size_t vertex)
{
    state.path[state.depth++] = vertex;
    state.blocked[vertex] = true;
    bool found = false;
    for (std::size_t neighbor = 0; neighbor < state.n; ++neighbor) {
        if (!state.inside[neighbor] || !state.edge[vertex * MaxVertices + neighbor]) continue;
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
        for (std::size_t neighbor = 0; neighbor < state.n; ++neighbor)
            if (state.inside[neighbor] && state.edge[vertex * MaxVertices + neighbor])
                state.dependency[neighbor * MaxVertices + vertex] = true;
    }
    --state.depth;
    return found;
}
}

extern "C" std::int64_t johnson_elementary_circuit_enumeration(const std::int64_t *input,
                                                                 std::size_t length) noexcept
{
    if (input == nullptr || length < 2 || length > MaxInputLength) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MaxVertices) || input[1] < 0 ||
        input[1] > static_cast<std::int64_t>(MaxEdges)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * m) return -1;

    std::array<bool, MaxVertices * MaxVertices> edge{};
    for (std::size_t e = 0; e < m; ++e) {
        const auto u_value = input[2 + 2 * e], v_value = input[3 + 2 * e];
        if (u_value < 0 || u_value >= static_cast<std::int64_t>(n) || v_value < 0 ||
            v_value >= static_cast<std::int64_t>(n) || u_value == v_value) return -1;
        const auto slot = static_cast<std::size_t>(u_value) * MaxVertices + static_cast<std::size_t>(v_value);
        if (edge[slot]) return -1;
        edge[slot] = true;
    }

    std::int64_t total_count = 0, total_code_sum = 0;
    std::size_t lower_bound = 0;
    while (lower_bound < n) {
        SccState scc;
        scc.edge = edge;
        scc.n = n;
        scc.lower_bound = lower_bound;
        scc.index.fill(-1);
        scc.component_id.fill(-1);
        for (std::size_t vertex = lower_bound; vertex < n; ++vertex)
            if (scc.index[vertex] < 0) strong_connect(vertex, scc);

        std::size_t start = n;
        int selected_component = -1;
        for (std::size_t component = 0; component < scc.component_count; ++component)
            if (scc.component_size[component] > 1 && scc.component_minimum[component] < start) {
                start = scc.component_minimum[component];
                selected_component = static_cast<int>(component);
            }
        if (selected_component < 0) break;

        JohnsonState state;
        state.n = n;
        state.start = start;
        for (std::size_t u = lower_bound; u < n; ++u) {
            state.inside[u] = scc.component_id[u] == selected_component;
            for (std::size_t v = 0; v < n; ++v) state.edge[u * MaxVertices + v] = edge[u * MaxVertices + v];
        }
        (void)circuit(state, start);
        total_count += state.count;
        total_code_sum += state.code_sum;
        lower_bound = start + 1;
    }
    return total_count * CountScale + total_code_sum;
}
