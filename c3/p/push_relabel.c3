module push_relabel;

const usz MAX_VERTICES = 14;
const usz AUGMENTED_VERTICES = 16;
const usz MAX_INPUT_LENGTH = 227;
const long MAX_CAPACITY = 1000000;

fn long push_relabel(long* input, usz length) @export("push_relabel") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long n64 = input[0], source_count64 = input[1];
    if (n64 < 2 || n64 > MAX_VERTICES || source_count64 < 1 || source_count64 >= n64) return -1;
    usz n = (usz)n64, source_count = (usz)source_count64;
    usz sink_count_index = 2 + source_count;
    if (length <= sink_count_index) return -1;

    bool[MAX_VERTICES] is_source;
    bool[MAX_VERTICES] is_sink;
    usz[MAX_VERTICES] sources;
    for (usz vertex = 0; vertex < MAX_VERTICES; vertex++) {
        is_source[vertex] = false;
        is_sink[vertex] = false;
        sources[vertex] = 0;
    }
    for (usz index = 0; index < source_count; index++) {
        long node64 = input[2 + index];
        if (node64 < 0 || node64 >= n64 || is_source[(usz)node64]) return -1;
        sources[index] = (usz)node64;
        is_source[(usz)node64] = true;
    }
    long sink_count64 = input[sink_count_index];
    if (sink_count64 < 1 || sink_count64 > n64 - source_count64) return -1;
    usz sink_count = (usz)sink_count64;
    usz matrix_start = sink_count_index + 1 + sink_count;
    if (length < matrix_start || length != matrix_start + n * n) return -1;
    for (usz index = 0; index < sink_count; index++) {
        long node64 = input[sink_count_index + 1 + index];
        if (node64 < 0 || node64 >= n64 || is_sink[(usz)node64] || is_source[(usz)node64]) return -1;
        is_sink[(usz)node64] = true;
    }

    long[AUGMENTED_VERTICES * AUGMENTED_VERTICES] residual;
    long[MAX_VERTICES] source_out;
    long flow_limit = 0;
    for (usz vertex = 0; vertex < MAX_VERTICES; vertex++) source_out[vertex] = 0;
    for (usz cell = 0; cell < AUGMENTED_VERTICES * AUGMENTED_VERTICES; cell++) residual[cell] = 0;
    for (usz row = 0; row < n; row++) {
        for (usz column = 0; column < n; column++) {
            long capacity = input[matrix_start + row * n + column];
            if (capacity < 0 || capacity > MAX_CAPACITY || (row == column && capacity != 0)) return -1;
            residual[row * AUGMENTED_VERTICES + column] = capacity;
            if (is_source[row]) {
                source_out[row] += capacity;
                flow_limit += capacity;
            }
        }
    }
    usz super_source = n, super_sink = n + 1;
    for (usz index = 0; index < source_count; index++) residual[super_source * AUGMENTED_VERTICES + sources[index]] = source_out[sources[index]];
    for (usz index = 0; index < sink_count; index++) {
        usz sink = (usz)input[sink_count_index + 1 + index];
        residual[sink * AUGMENTED_VERTICES + super_sink] = flow_limit;
    }

    int[AUGMENTED_VERTICES] height;
    long[AUGMENTED_VERTICES] excess;
    bool[AUGMENTED_VERTICES] active;
    for (usz vertex = 0; vertex < AUGMENTED_VERTICES; vertex++) {
        height[vertex] = 0;
        excess[vertex] = 0;
        active[vertex] = false;
    }
    height[super_source] = (int)n + 2;
    for (usz index = 0; index < source_count; index++) {
        usz source = sources[index];
        long initial_excess = residual[super_source * AUGMENTED_VERTICES + source];
        residual[super_source * AUGMENTED_VERTICES + source] = 0;
        residual[source * AUGMENTED_VERTICES + super_source] += initial_excess;
        excess[source] += initial_excess;
        if (excess[source] > 0) active[source] = true;
    }

    while (true) {
        usz node = 0;
        while (node < n && !active[node]) node++;
        if (node == n) break;
        active[node] = false;
        while (excess[node] > 0) {
            bool pushed = false;
            for (usz neighbor = 0; neighbor < n + 2 && excess[node] > 0; neighbor++) {
                usz edge = node * AUGMENTED_VERTICES + neighbor;
                if (residual[edge] <= 0 || height[node] != height[neighbor] + 1) continue;
                long amount = excess[node] < residual[edge] ? excess[node] : residual[edge];
                residual[edge] -= amount;
                residual[neighbor * AUGMENTED_VERTICES + node] += amount;
                excess[node] -= amount;
                long previous_excess = excess[neighbor];
                excess[neighbor] += amount;
                if (neighbor < n && previous_excess == 0) active[neighbor] = true;
                pushed = true;
            }
            if (excess[node] > 0 && !pushed) {
                int minimum_height = 1000;
                for (usz neighbor = 0; neighbor < n + 2; neighbor++)
                    if (residual[node * AUGMENTED_VERTICES + neighbor] > 0 && height[neighbor] < minimum_height)
                        minimum_height = height[neighbor];
                if (minimum_height == 1000) return -1;
                height[node] = minimum_height + 1;
            }
        }
    }
    return excess[super_sink];
}
