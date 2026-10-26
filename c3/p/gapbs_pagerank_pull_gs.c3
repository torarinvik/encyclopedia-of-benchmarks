module gapbs_pagerank_pull_gs;

const usz MAX_N = 8;
const usz MAX_INPUT = 2 + MAX_N * MAX_N;

fn long gapbs_pagerank_pull_gs(long* input, usz length) @export("gapbs_pagerank_pull_gs") {
    if (input == null || length < 6 || length > MAX_INPUT) return -1;
    long n_value = input[0], iterations_value = input[1];
    if (n_value < 2 || n_value > (long)MAX_N || iterations_value < 0 || iterations_value > 20) return -1;
    usz n = (usz)n_value, iterations = (usz)iterations_value;
    if (length != 2 + n * n) return -1;
    uint8[64] matrix = {0};
    usz[8] outdegree = {0};
    for (usz row = 0; row < n; row++) {
        for (usz column = 0; column < n; column++) {
            long value = input[2 + row * n + column];
            if ((value != 0 && value != 1) || (row == column && value != 0)) return -1;
            matrix[row * n + column] = (uint8)value;
            outdegree[row] += (usz)value;
        }
        if (outdegree[row] == 0) return -1;
    }
    float damping = 0.85;
    float init_score = 1.0f / (float)n;
    float base_score = (1.0f - damping) / (float)n;
    float[8] scores = {0}, outgoing = {0};
    for (usz node = 0; node < n; node++) {
        scores[node] = init_score;
        outgoing[node] = init_score / (float)outdegree[node];
    }
    for (usz iteration = 0; iteration < iterations; iteration++) {
        for (usz target = 0; target < n; target++) {
            float incoming = 0.0f;
            for (usz source = 0; source < n; source++)
                if (matrix[source * n + target] != 0) incoming += outgoing[source];
            scores[target] = base_score + damping * incoming;
            outgoing[target] = scores[target] / (float)outdegree[target];
        }
    }
    double weighted = 0.0;
    for (usz node = 0; node < n; node++) weighted += (double)(node + 1) * (double)scores[node];
    return (long)(weighted * 100.0 + 0.5);
}
