#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 512 };
static const int64_t MODULUS = INT64_C(998244353);

static int64_t mod_pow(int64_t base, int exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

static int64_t solve(int n) {
    int64_t factorial[MAX_N + 1] = {0};
    int64_t inverse_factorial[MAX_N + 1] = {0};
    int64_t all_graphs[MAX_N + 1] = {0};
    int64_t connected[MAX_N + 1] = {0};
    factorial[0] = 1;
    for (int i = 1; i <= n; ++i) factorial[i] = factorial[i - 1] * i % MODULUS;
    inverse_factorial[n] = mod_pow(factorial[n], 998244351);
    for (int i = n; i > 0; --i) inverse_factorial[i - 1] = inverse_factorial[i] * i % MODULUS;

    all_graphs[0] = 1;
    int64_t edge_choices = 1;
    for (int size = 1; size <= n; ++size) {
        all_graphs[size] = all_graphs[size - 1] * edge_choices % MODULUS;
        edge_choices = edge_choices * 2 % MODULUS;
    }
    connected[1] = 1;
    for (int size = 2; size <= n; ++size) {
        int64_t disconnected = 0;
        for (int component_size = 1; component_size < size; ++component_size) {
            int64_t choose = factorial[size - 1] * inverse_factorial[component_size - 1] % MODULUS;
            choose = choose * inverse_factorial[size - component_size] % MODULUS;
            int64_t term = choose * connected[component_size] % MODULUS;
            term = term * all_graphs[size - component_size] % MODULUS;
            disconnected = (disconnected + term) % MODULUS;
        }
        connected[size] = (all_graphs[size] - disconnected + MODULUS) % MODULUS;
    }
    return connected[n];
}

int64_t connected_labeled_graph_count(const int64_t *input, size_t length) {
    if (!input || length != 1 || input[0] < 1 || input[0] > MAX_N) return -1;
    return solve((int)input[0]);
}
