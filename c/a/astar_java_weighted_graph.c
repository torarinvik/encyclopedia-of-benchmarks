#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 7
#define MAX_STATES 4096

typedef struct {
    int32_t distance;
    int32_t heuristic;
    int32_t length;
    int32_t path[MAX_VERTICES];
} SearchState;

static void write_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (unsigned shift = 0; shift < 64; shift += 8) output[offset++] = (uint8_t)(bits >> shift);
}

int64_t astar_java_weighted_graph(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity) {
    if (input == NULL || length < 5) return -1;
    const int64_t n64 = input[0], m64 = input[1], start64 = input[2], target64 = input[3];
    if (n64 < 1 || n64 > MAX_VERTICES || m64 < 0 || m64 > 16 ||
        start64 < 0 || start64 >= n64 || target64 < 0 || target64 >= n64 ||
        length != (size_t)(4 + n64 + 3 * m64)) return -1;
    const int n = (int)n64, m = (int)m64, start = (int)start64, target = (int)target64;
    int32_t heuristic[MAX_VERTICES] = {0};
    int32_t adjacent[MAX_VERTICES][MAX_VERTICES] = {{0}};
    int32_t weights[MAX_VERTICES][MAX_VERTICES] = {{0}};
    int degree[MAX_VERTICES] = {0};
    for (int i = 0; i < n; ++i) {
        if (input[4 + i] < -1000 || input[4 + i] > 1000) return -1;
        heuristic[i] = (int32_t)input[4 + i];
    }
    size_t position = (size_t)(4 + n);
    for (int edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[position], v64 = input[position + 1], weight64 = input[position + 2];
        position += 3;
        if (u64 < 0 || u64 >= n || v64 < 0 || v64 >= n || u64 == v64 || weight64 < 0 || weight64 > 1000) return -1;
        const int u = (int)u64, v = (int)v64;
        for (int i = 0; i < degree[u]; ++i) if (adjacent[u][i] == v) return -1;
        adjacent[u][degree[u]] = v; weights[u][degree[u]++] = (int32_t)weight64;
        adjacent[v][degree[v]] = u; weights[v][degree[v]++] = (int32_t)weight64;
    }
    SearchState states[MAX_STATES];
    int32_t heap[MAX_STATES];
    size_t state_count = 1, heap_size = 1;
    states[0].distance = 0; states[0].heuristic = heuristic[start]; states[0].length = 1;
    states[0].path[0] = start;
    heap[0] = 0;
    int found = 0;
    int32_t solution = -1;
    while (heap_size > 0) {
        const int32_t current_index = heap[0];
        const int32_t last = heap[--heap_size];
        if (heap_size > 0) {
            size_t i = 0, half = heap_size / 2;
            while (i < half) {
                size_t child = 2 * i + 1;
                int32_t child_index = heap[child];
                const size_t right = child + 1;
                if (right < heap_size &&
                    states[heap[right]].distance + states[heap[right]].heuristic <
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
        const int32_t current_vertex = current.path[current.length - 1];
        if (current_vertex == target) { found = 1; solution = current_index; break; }
        for (int edge = 0; edge < degree[current_vertex]; ++edge) {
            const int32_t next = adjacent[current_vertex][edge];
            int in_path = 0;
            for (int i = 0; i < current.length; ++i) if (current.path[i] == next) { in_path = 1; break; }
            if (in_path) continue;
            if (state_count >= MAX_STATES || heap_size >= MAX_STATES) return -1;
            const int32_t next_state = (int32_t)state_count++;
            SearchState *child_state = &states[next_state];
            child_state->distance = current.distance + weights[current_vertex][edge];
            child_state->heuristic = heuristic[next];
            child_state->length = current.length + 1;
            for (int i = 0; i < current.length; ++i) child_state->path[i] = current.path[i];
            child_state->path[current.length] = next;
            size_t i = heap_size++;
            while (i > 0) {
                const size_t parent = (i - 1) / 2;
                const int32_t parent_index = heap[parent];
                if (states[parent_index].distance + states[parent_index].heuristic <=
                    child_state->distance + child_state->heuristic) break;
                heap[i] = parent_index; i = parent;
            }
            heap[i] = next_state;
        }
    }
    int64_t result[3 + MAX_VERTICES];
    size_t result_words = 3;
    if (!found) { result[0] = -1; result[1] = -1; result[2] = 0; }
    else {
        const SearchState *state = &states[solution];
        result[0] = state->distance; result[1] = state->heuristic; result[2] = state->length;
        result_words += (size_t)state->length;
        for (int i = 0; i < state->length; ++i) result[3 + i] = state->path[i];
    }
    const size_t output_bytes = result_words * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < result_words; ++i) write_i64(output, i * 8, result[i]);
    return (int64_t)output_bytes;
}
