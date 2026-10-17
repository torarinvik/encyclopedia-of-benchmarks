module stoer_wagner;

const usz MAX_N = 16;
const usz MAX_INPUT_VALUES = 257;
const long MAX_WEIGHT = 1000000;

fn long stoer_wagner_impl(long* input, usz length) {
    if (input == null || length < 1 || length > MAX_INPUT_VALUES) return -1;
    long n_value = input[0];
    if (n_value < 2 || n_value > 16) return -1;
    usz n = (usz)n_value;
    if (length != 1 + n * n) return -1;

    long[256] graph;
    for (usz i = 0; i < 256; i++) graph[i] = 0;
    for (usz i = 0; i < n; i++) {
        for (usz j = 0; j < n; j++) {
            long weight = input[1 + i * n + j];
            if (weight < 0 || weight > MAX_WEIGHT) return -1;
            graph[i * MAX_N + j] = weight;
        }
    }
    for (usz i = 0; i < n; i++) {
        if (graph[i * MAX_N + i] != 0) return -1;
        for (usz j = i + 1; j < n; j++) {
            if (graph[i * MAX_N + j] != graph[j * MAX_N + i]) return -1;
        }
    }

    bool[16] merged;
    for (usz i = 0; i < MAX_N; i++) merged[i] = false;
    long min_cut = 120000001;
    for (usz phase = 0; phase < n - 1; phase++) {
        bool[16] in_set;
        long[16] weights;
        for (usz i = 0; i < MAX_N; i++) { in_set[i] = false; weights[i] = 0; }
        long previous = -1;
        long last = -1;
        for (usz step = 0; step < n - phase; step++) {
            long current = -1;
            long max_weight = -1;
            for (usz vertex = 0; vertex < n; vertex++) {
                if (!merged[vertex] && !in_set[vertex] && weights[vertex] > max_weight) {
                    max_weight = weights[vertex];
                    current = (long)vertex;
                }
            }
            if (current < 0) break;
            usz current_index = (usz)current;
            in_set[current_index] = true;
            previous = last;
            last = current;
            for (usz vertex = 0; vertex < n; vertex++) {
                if (!merged[vertex] && !in_set[vertex]) {
                    weights[vertex] += graph[current_index * MAX_N + vertex];
                }
            }
        }
        if (last < 0 || previous < 0) return -1;
        usz last_index = (usz)last;
        usz previous_index = (usz)previous;
        if (weights[last_index] < min_cut) min_cut = weights[last_index];
        for (usz vertex = 0; vertex < n; vertex++) {
            graph[previous_index * MAX_N + vertex] += graph[last_index * MAX_N + vertex];
            graph[vertex * MAX_N + previous_index] = graph[previous_index * MAX_N + vertex];
        }
        merged[last_index] = true;
    }
    return min_cut;
}

fn long stoer_wagner(long* input, usz length) @export("stoer_wagner") {
    return stoer_wagner_impl(input, length);
}
