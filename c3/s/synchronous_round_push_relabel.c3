module synchronous_round_push_relabel;

const int MAX_VERTICES = 8;
const int MAX_ARCS = 24;
const usz MAX_INPUT_LENGTH = 77;
const long MAX_CAPACITY = 15;

fn long synchronous_round_push_relabel(long* input, usz length) @export("synchronous_round_push_relabel") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    long raw_n = input[0], raw_m = input[1], raw_source = input[2], raw_sink = input[3];
    if (raw_n < 2 || raw_n > MAX_VERTICES || raw_m < 0 || raw_m > MAX_ARCS ||
        raw_source < 0 || raw_source >= raw_n || raw_sink < 0 || raw_sink >= raw_n ||
        raw_source == raw_sink || length != 4 + 3 * (usz)raw_m) return -1;
    int n = (int)raw_n, m = (int)raw_m;
    int source = (int)raw_source, sink = (int)raw_sink;
    long[MAX_VERTICES * MAX_VERTICES] capacity = zeroed;
    for (int i = 0; i < m; i += 1) {
        usz offset = 4 + 3 * (usz)i;
        long u = input[offset], v = input[offset + 1], c = input[offset + 2];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v || c < 0 || c > MAX_CAPACITY)
            return -1;
        capacity[(usz)((int)u * MAX_VERTICES + (int)v)] += c;
    }

    long[MAX_VERTICES * MAX_VERTICES] residual = capacity;
    long[MAX_VERTICES] excess = zeroed;
    int[MAX_VERTICES] height = zeroed;
    height[source] = n;
    for (int v = 0; v < n; v += 1) {
        if (v == source) continue;
        usz forward = (usz)(source * MAX_VERTICES + v);
        usz reverse = (usz)(v * MAX_VERTICES + source);
        long amount = residual[forward];
        if (amount != 0) {
            residual[forward] = 0;
            residual[reverse] += amount;
            excess[source] -= amount;
            excess[v] += amount;
        }
    }

    for (;;) {
        int[MAX_VERTICES] active = zeroed;
        int active_count = 0;
        for (int v = 0; v < n; v += 1)
            if (v != source && v != sink && excess[v] > 0 && height[v] < n)
                active[active_count++] = v;
        if (active_count == 0) return excess[sink];

        long[MAX_VERTICES] change = zeroed;
        for (int ai = 0; ai < active_count; ai += 1) {
            int u = active[ai];
            long remaining = excess[u];
            for (int v = 0; v < n && remaining > 0; v += 1) {
                usz forward = (usz)(u * MAX_VERTICES + v);
                usz reverse = (usz)(v * MAX_VERTICES + u);
                if (residual[forward] > 0 && height[u] == height[v] + 1) {
                    long amount = remaining < residual[forward] ? remaining : residual[forward];
                    residual[forward] -= amount;
                    residual[reverse] += amount;
                    change[u] -= amount;
                    change[v] += amount;
                    remaining -= amount;
                }
            }
        }

        long[MAX_VERTICES] next_excess;
        int[MAX_VERTICES] next_height;
        for (int v = 0; v < n; v += 1) {
            next_excess[v] = excess[v] + change[v];
            next_height[v] = height[v];
        }
        for (int ai = 0; ai < active_count; ai += 1) {
            int u = active[ai];
            if (next_excess[u] <= 0) continue;
            int minimum = 2 * MAX_VERTICES + 1;
            for (int v = 0; v < n; v += 1)
                if (residual[(usz)(u * MAX_VERTICES + v)] > 0 && height[v] < minimum)
                    minimum = height[v];
            next_height[u] = minimum == 2 * MAX_VERTICES + 1 ? n + 1 : minimum + 1;
        }
        for (int v = 0; v < n; v += 1) {
            excess[v] = next_excess[v];
            height[v] = next_height[v];
        }
    }
}
