module functional_graph_cycle_parameters;

const int MAX_N = 64;
const long ENCODING_BASE = 65;

fn long next_node(long* input, long node) {
    return input[2 + node];
}

fn long cycle_parameters(long* input, long start) {
    long tortoise = next_node(input, start);
    long hare = next_node(input, next_node(input, start));
    while (tortoise != hare) {
        tortoise = next_node(input, tortoise);
        hare = next_node(input, next_node(input, hare));
    }
    long mu = 0;
    tortoise = start;
    while (tortoise != hare) {
        tortoise = next_node(input, tortoise);
        hare = next_node(input, hare);
        mu++;
    }
    long lambda = 1;
    hare = next_node(input, tortoise);
    while (hare != tortoise) {
        hare = next_node(input, hare);
        lambda++;
    }
    return ENCODING_BASE * mu + lambda;
}

fn long functional_graph_cycle_parameters(long* input, usz length) @export("functional_graph_cycle_parameters") {
    if (input == null || length < 3 || length > MAX_N + 2) return -1;
    long n = input[0];
    long start = input[1];
    if (n < 1 || n > MAX_N || start < 0 || start >= n || length != n + 2) return -1;
    for (long i = 0; i < n; i++) {
        if (input[2 + i] < 0 || input[2 + i] >= n) return -1;
    }
    return cycle_parameters(input, start);
}
