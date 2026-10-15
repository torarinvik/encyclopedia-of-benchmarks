#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxVertices = 7;
constexpr std::size_t kMaxStates = 4096;
struct SearchState {
    std::int32_t distance;
    std::int32_t heuristic;
    std::int32_t length;
    std::int32_t path[kMaxVertices];
};
void write_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (unsigned shift = 0; shift < 64; shift += 8) output[offset++] = static_cast<std::uint8_t>(bits >> shift);
}
}

extern "C" std::int64_t astar_java_weighted_graph(const std::int64_t *input, std::size_t length,
                                                   std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 5) return -1;
    const auto n64 = input[0], m64 = input[1], start64 = input[2], target64 = input[3];
    if (n64 < 1 || n64 > kMaxVertices || m64 < 0 || m64 > 16 || start64 < 0 || start64 >= n64 ||
        target64 < 0 || target64 >= n64 || length != static_cast<std::size_t>(4 + n64 + 3 * m64)) return -1;
    const int n = static_cast<int>(n64), m = static_cast<int>(m64);
    const int start = static_cast<int>(start64), target = static_cast<int>(target64);
    std::int32_t heuristic[kMaxVertices]{};
    std::int32_t adjacent[kMaxVertices][kMaxVertices]{};
    std::int32_t weights[kMaxVertices][kMaxVertices]{};
    int degree[kMaxVertices]{};
    for (int i = 0; i < n; ++i) {
        if (input[4 + i] < -1000 || input[4 + i] > 1000) return -1;
        heuristic[i] = static_cast<std::int32_t>(input[4 + i]);
    }
    std::size_t position = static_cast<std::size_t>(4 + n);
    for (int edge = 0; edge < m; ++edge) {
        const auto u64 = input[position], v64 = input[position + 1], weight64 = input[position + 2];
        position += 3;
        if (u64 < 0 || u64 >= n || v64 < 0 || v64 >= n || u64 == v64 || weight64 < 0 || weight64 > 1000) return -1;
        const int u = static_cast<int>(u64), v = static_cast<int>(v64);
        for (int i = 0; i < degree[u]; ++i) if (adjacent[u][i] == v) return -1;
        adjacent[u][degree[u]] = v; weights[u][degree[u]++] = static_cast<std::int32_t>(weight64);
        adjacent[v][degree[v]] = u; weights[v][degree[v]++] = static_cast<std::int32_t>(weight64);
    }
    SearchState states[kMaxStates];
    std::int32_t heap[kMaxStates];
    std::size_t state_count = 1, heap_size = 1;
    states[0].distance = 0; states[0].heuristic = heuristic[start]; states[0].length = 1;
    states[0].path[0] = start; heap[0] = 0;
    bool found = false;
    std::int32_t solution = -1;
    while (heap_size > 0) {
        const auto current_index = heap[0];
        const auto last = heap[--heap_size];
        if (heap_size > 0) {
            std::size_t i = 0, half = heap_size / 2;
            while (i < half) {
                std::size_t child = 2 * i + 1;
                auto child_index = heap[child];
                const auto right = child + 1;
                if (right < heap_size && states[heap[right]].distance + states[heap[right]].heuristic <
                                         states[child_index].distance + states[child_index].heuristic) {
                    child = right; child_index = heap[right];
                }
                if (states[last].distance + states[last].heuristic <=
                    states[child_index].distance + states[child_index].heuristic) break;
                heap[i] = child_index; i = child;
            }
            heap[i] = last;
        }
        const SearchState current = states[current_index];
        const auto current_vertex = current.path[current.length - 1];
        if (current_vertex == target) { found = true; solution = current_index; break; }
        for (int edge = 0; edge < degree[current_vertex]; ++edge) {
            const auto next = adjacent[current_vertex][edge];
            bool in_path = false;
            for (int i = 0; i < current.length; ++i) if (current.path[i] == next) { in_path = true; break; }
            if (in_path) continue;
            if (state_count >= kMaxStates || heap_size >= kMaxStates) return -1;
            const auto next_state = static_cast<std::int32_t>(state_count++);
            auto &child_state = states[next_state];
            child_state.distance = current.distance + weights[current_vertex][edge];
            child_state.heuristic = heuristic[next];
            child_state.length = current.length + 1;
            for (int i = 0; i < current.length; ++i) child_state.path[i] = current.path[i];
            child_state.path[current.length] = next;
            std::size_t i = heap_size++;
            while (i > 0) {
                const auto parent = (i - 1) / 2;
                const auto parent_index = heap[parent];
                if (states[parent_index].distance + states[parent_index].heuristic <=
                    child_state.distance + child_state.heuristic) break;
                heap[i] = parent_index; i = parent;
            }
            heap[i] = next_state;
        }
    }
    std::int64_t result[3 + kMaxVertices]{};
    std::size_t result_words = 3;
    if (!found) { result[0] = -1; result[1] = -1; result[2] = 0; }
    else {
        const auto &state = states[solution];
        result[0] = state.distance; result[1] = state.heuristic; result[2] = state.length;
        result_words += static_cast<std::size_t>(state.length);
        for (int i = 0; i < state.length; ++i) result[3 + i] = state.path[i];
    }
    const auto output_bytes = result_words * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < result_words; ++i) write_i64(output, i * 8, result[i]);
    return static_cast<std::int64_t>(output_bytes);
}
