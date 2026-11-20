module scc_condensation_dag;

const usz MAX_N = 8;
const usz MAX_M = 28;
const usz MAX_INPUT_LENGTH = 58;
const usz MAX_OUTPUT_BYTES = 17;

fn long scc_condensation_dag(long* input, usz length, u8* output,
                             usz capacity) @export("scc_condensation_dag") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0], m_value = input[1];
    if (n_value < 0 || n_value > (long)MAX_N || m_value < 0 || m_value > (long)MAX_M) return -1;
    usz n = (usz)n_value, m = (usz)m_value;
    if (length != 2 + 2 * m) return -1;
    long[8] adjacency = zeroed;
    long[8] reverse = zeroed;
    for (usz i = 0; i < m; i++) {
        long source = input[2 + 2 * i], target = input[3 + 2 * i];
        if (source < 0 || source >= n_value || target < 0 || target >= n_value) return -1;
        adjacency[(usz)source] |= 1L << (usz)target;
        reverse[(usz)target] |= 1L << (usz)source;
    }
    bool[8] visited = zeroed;
    u8[8] order, stack_vertex, stack_next;
    usz order_count = 0;
    for (usz start = 0; start < n; start++) {
        if (visited[start]) continue;
        usz stack_size = 1;
        stack_vertex[0] = (u8)start; stack_next[0] = 0; visited[start] = true;
        while (stack_size > 0) {
            usz frame = stack_size - 1, vertex = (usz)stack_vertex[frame];
            usz candidate = (usz)stack_next[frame];
            while (candidate < n && (adjacency[vertex] & (1L << candidate)) == 0) candidate++;
            if (candidate < n) {
                stack_next[frame] = (u8)(candidate + 1);
                if (!visited[candidate]) {
                    visited[candidate] = true;
                    stack_vertex[stack_size] = (u8)candidate; stack_next[stack_size] = 0;
                    stack_size++;
                }
            } else {
                order[order_count++] = (u8)vertex;
                stack_size--;
            }
        }
    }
    long[8] raw_component;
    for (usz i = 0; i < n; i++) raw_component[i] = -1;
    for (usz i = 0; i < n; i++) visited[i] = false;
    usz component_count = 0;
    while (order_count > 0) {
        usz start = (usz)order[--order_count];
        if (visited[start]) continue;
        usz stack_size = 1;
        stack_vertex[0] = (u8)start; visited[start] = true;
        raw_component[start] = (long)component_count;
        while (stack_size > 0) {
            usz vertex = (usz)stack_vertex[--stack_size];
            for (usz next = 0; next < n; next++) {
                if ((reverse[vertex] & (1L << next)) != 0 && !visited[next]) {
                    visited[next] = true; raw_component[next] = (long)component_count;
                    stack_vertex[stack_size++] = (u8)next;
                }
            }
        }
        component_count++;
    }
    u8[8] minimum, raw_order, canonical, labels;
    u8[8] row_mask = zeroed;
    for (usz component = 0; component < component_count; component++) {
        minimum[component] = (u8)n; raw_order[component] = (u8)component;
    }
    for (usz vertex = 0; vertex < n; vertex++) {
        usz component = (usz)raw_component[vertex];
        if (vertex < minimum[component]) minimum[component] = (u8)vertex;
    }
    for (usz i = 1; i < component_count; i++) {
        u8 key = raw_order[i];
        usz j = i;
        while (j > 0 && minimum[raw_order[j - 1]] > minimum[key]) {
            raw_order[j] = raw_order[j - 1]; j--;
        }
        raw_order[j] = key;
    }
    for (usz i = 0; i < component_count; i++) canonical[raw_order[i]] = (u8)i;
    for (usz vertex = 0; vertex < n; vertex++) labels[vertex] = canonical[(usz)raw_component[vertex]];
    for (usz source = 0; source < n; source++) {
        for (usz target = 0; target < n; target++) {
            if ((adjacency[source] & (1L << target)) == 0) continue;
            u8 left = labels[source], right = labels[target];
            if (left != right) row_mask[left] |= (u8)(1u << right);
        }
    }
    u8[17] staged;
    staged[0] = (u8)component_count;
    for (usz vertex = 0; vertex < n; vertex++) staged[1 + vertex] = labels[vertex];
    for (usz component = 0; component < component_count; component++) staged[1 + n + component] = row_mask[component];
    usz output_size = 1 + n + component_count;
    if (output == null || capacity < output_size) return -2;
    for (usz i = 0; i < output_size; i++) output[i] = staged[i];
    return (long)output_size;
}
