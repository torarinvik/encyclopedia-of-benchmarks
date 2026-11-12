module connected_labeled_graph_count;

const int MAX_N = 512;
const long MODULUS = 998244353;

fn long mod_pow(long base, int exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn long solve(int n) {
    long[MAX_N + 1] factorial = {};
    long[MAX_N + 1] inverse_factorial = {};
    long[MAX_N + 1] all_graphs = {};
    long[MAX_N + 1] connected = {};
    factorial[0] = 1;
    for (int i = 1; i <= n; i++) factorial[i] = factorial[i - 1] * i % MODULUS;
    inverse_factorial[n] = mod_pow(factorial[n], 998244351);
    for (int i = n; i > 0; i--) inverse_factorial[i - 1] = inverse_factorial[i] * i % MODULUS;

    all_graphs[0] = 1;
    long edge_choices = 1;
    for (int size = 1; size <= n; size++) {
        all_graphs[size] = all_graphs[size - 1] * edge_choices % MODULUS;
        edge_choices = edge_choices * 2 % MODULUS;
    }
    connected[1] = 1;
    for (int size = 2; size <= n; size++) {
        long disconnected = 0;
        for (int component_size = 1; component_size < size; component_size++) {
            long choose = factorial[size - 1] * inverse_factorial[component_size - 1] % MODULUS;
            choose = choose * inverse_factorial[size - component_size] % MODULUS;
            long term = choose * connected[component_size] % MODULUS;
            term = term * all_graphs[size - component_size] % MODULUS;
            disconnected = (disconnected + term) % MODULUS;
        }
        connected[size] = (all_graphs[size] - disconnected + MODULUS) % MODULUS;
    }
    return connected[n];
}

fn long connected_labeled_graph_count(long* input, usz length) @export("connected_labeled_graph_count") {
    if (input == null || length != 1 || input[0] < 1 || input[0] > MAX_N) return -1;
    return solve((int)input[0]);
}
