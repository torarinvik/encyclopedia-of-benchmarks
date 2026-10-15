module astar_java_weighted_graph;

const int MAX_VERTICES = 7;
const usz MAX_STATES = 4096;
struct SearchState { int distance; int heuristic; int length; int path[7]; }

fn void write_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz shift = 0; shift < 64; shift += 8) output[offset++] = (char)((bits >> shift) & 255);
}

fn long astar_java_weighted_graph(long* input, usz length, char* output, usz capacity) @export("astar_java_weighted_graph") {
    if (input == null || length < 5) return -1;
    long n_value = input[0], m_value = input[1], start_value = input[2], target_value = input[3];
    if (n_value < 1 || n_value > MAX_VERTICES || m_value < 0 || m_value > 16 ||
        start_value < 0 || start_value >= n_value || target_value < 0 || target_value >= n_value ||
        length != (4 + n_value + 3 * m_value).usz()) return -1;
    int n = (int)n_value, m = (int)m_value, start = (int)start_value, target = (int)target_value;
    int[7] heuristic = {}, degree = {};
    int[7][7] adjacent = {}, weights = {};
    for (int i = 0; i < n; i++) {
        if (input[4 + i] < -1000 || input[4 + i] > 1000) return -1;
        heuristic[i] = (int)input[4 + i];
    }
    usz position = (4 + n).usz();
    for (int edge = 0; edge < m; edge++) {
        long u_value = input[position], v_value = input[position + 1], weight_value = input[position + 2];
        position += 3;
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value ||
            u_value == v_value || weight_value < 0 || weight_value > 1000) return -1;
        int u = (int)u_value, v = (int)v_value;
        for (int i = 0; i < degree[u]; i++) if (adjacent[u][i] == v) return -1;
        adjacent[u][degree[u]] = v; weights[u][degree[u]++] = (int)weight_value;
        adjacent[v][degree[v]] = u; weights[v][degree[v]++] = (int)weight_value;
    }
    SearchState[MAX_STATES] states;
    int[MAX_STATES] heap;
    usz state_count = 1, heap_size = 1;
    states[0].distance = 0; states[0].heuristic = heuristic[start]; states[0].length = 1;
    states[0].path[0] = start; heap[0] = 0;
    bool found = false;
    int solution = -1;
    while (heap_size > 0) {
        int current_index = heap[0];
        int last = heap[heap_size - 1];
        heap_size--;
        if (heap_size > 0) {
            usz i = 0, half = heap_size / 2;
            while (i < half) {
                usz child = 2 * i + 1;
                int child_index = heap[child];
                usz right = child + 1;
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
        SearchState current = states[current_index];
        int current_vertex = current.path[current.length - 1];
        if (current_vertex == target) { found = true; solution = current_index; break; }
        for (int edge = 0; edge < degree[current_vertex]; edge++) {
            int next = adjacent[current_vertex][edge];
            bool in_path = false;
            for (int i = 0; i < current.length; i++) if (current.path[i] == next) { in_path = true; break; }
            if (in_path) continue;
            if (state_count >= MAX_STATES || heap_size >= MAX_STATES) return -1;
            int next_state = (int)state_count++;
            states[next_state].distance = current.distance + weights[current_vertex][edge];
            states[next_state].heuristic = heuristic[next];
            states[next_state].length = current.length + 1;
            for (int i = 0; i < current.length; i++) states[next_state].path[i] = current.path[i];
            states[next_state].path[current.length] = next;
            usz i = heap_size++;
            while (i > 0) {
                usz parent = (i - 1) / 2;
                int parent_index = heap[parent];
                if (states[parent_index].distance + states[parent_index].heuristic <=
                    states[next_state].distance + states[next_state].heuristic) break;
                heap[i] = parent_index; i = parent;
            }
            heap[i] = next_state;
        }
    }
    long[10] result = {};
    usz result_words = 3;
    if (!found) { result[0] = -1; result[1] = -1; result[2] = 0; }
    else {
        SearchState state = states[solution];
        result[0] = state.distance; result[1] = state.heuristic; result[2] = state.length;
        result_words += state.length.usz();
        for (int i = 0; i < state.length; i++) result[3 + i] = state.path[i];
    }
    usz output_bytes = result_words * 8;
    if (output == null || capacity < output_bytes) return -2;
    for (usz i = 0; i < result_words; i++) write_i64(output, i * 8, result[i]);
    return output_bytes.long();
}
