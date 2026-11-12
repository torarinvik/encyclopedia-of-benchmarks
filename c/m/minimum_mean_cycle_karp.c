#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 8, MAX_EDGES = 16, MAX_INPUT_LENGTH = 51, OUTPUT_BYTES = 16 };

typedef struct { size_t from; size_t to; int64_t weight; } Edge;

static int all_reachable(size_t n, const uint8_t adjacent[MAX_VERTICES][MAX_VERTICES], int reverse)
{
    uint8_t seen[MAX_VERTICES] = {0};
    size_t queue[MAX_VERTICES];
    size_t head = 0;
    size_t tail = 0;
    seen[0] = 1;
    queue[tail++] = 0;
    while (head < tail) {
        const size_t u = queue[head++];
        for (size_t v = 0; v < n; ++v) {
            const uint8_t has_edge = reverse ? adjacent[v][u] : adjacent[u][v];
            if (has_edge && !seen[v]) {
                seen[v] = 1;
                queue[tail++] = v;
            }
        }
    }
    for (size_t v = 0; v < n; ++v) if (!seen[v]) return 0;
    return 1;
}

static int ratio_less(int64_t a_num, int64_t a_den, int64_t b_num, int64_t b_den)
{
    return a_num * b_den < b_num * a_den;
}

static int64_t gcd_positive(int64_t a, int64_t b)
{
    while (b != 0) {
        const int64_t remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t minimum_mean_cycle_karp(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 1 || input[1] > MAX_EDGES) return -1;
    const size_t n = (size_t)input[0];
    const size_t edge_count = (size_t)input[1];
    if (edge_count > n * n || length != 2 + 3 * edge_count) return -1;

    Edge edges[MAX_EDGES];
    uint8_t adjacent[MAX_VERTICES][MAX_VERTICES] = {{0}};
    for (size_t i = 0; i < edge_count; ++i) {
        const int64_t from_value = input[2 + 3 * i];
        const int64_t to_value = input[3 + 3 * i];
        const int64_t weight = input[4 + 3 * i];
        if (from_value < 0 || from_value >= (int64_t)n
            || to_value < 0 || to_value >= (int64_t)n
            || weight < -1000 || weight > 1000) return -1;
        const size_t from = (size_t)from_value;
        const size_t to = (size_t)to_value;
        if (adjacent[from][to]) return -1;
        adjacent[from][to] = 1;
        edges[i] = (Edge){from, to, weight};
    }
    if (!all_reachable(n, adjacent, 0) || !all_reachable(n, adjacent, 1)) return -1;
    if (output == NULL || capacity < OUTPUT_BYTES) return -2;

    int64_t cost[MAX_VERTICES + 1][MAX_VERTICES] = {{0}};
    uint8_t reachable[MAX_VERTICES + 1][MAX_VERTICES] = {{0}};
    reachable[0][0] = 1;
    for (size_t length_k = 1; length_k <= n; ++length_k) {
        for (size_t e = 0; e < edge_count; ++e) {
            const Edge edge = edges[e];
            if (!reachable[length_k - 1][edge.from]) continue;
            const int64_t candidate = cost[length_k - 1][edge.from] + edge.weight;
            if (!reachable[length_k][edge.to] || candidate < cost[length_k][edge.to]) {
                reachable[length_k][edge.to] = 1;
                cost[length_k][edge.to] = candidate;
            }
        }
    }

    int have_answer = 0;
    int64_t answer_num = 0;
    int64_t answer_den = 1;
    for (size_t v = 0; v < n; ++v) {
        if (!reachable[n][v]) continue;
        int have_local = 0;
        int64_t local_num = 0;
        int64_t local_den = 1;
        for (size_t k = 0; k < n; ++k) {
            if (!reachable[k][v]) continue;
            const int64_t numerator = cost[n][v] - cost[k][v];
            const int64_t denominator = (int64_t)(n - k);
            if (!have_local || ratio_less(local_num, local_den, numerator, denominator)) {
                local_num = numerator;
                local_den = denominator;
                have_local = 1;
            }
        }
        if (have_local && (!have_answer || ratio_less(local_num, local_den, answer_num, answer_den))) {
            answer_num = local_num;
            answer_den = local_den;
            have_answer = 1;
        }
    }
    if (!have_answer) return -1;
    const int64_t divisor = gcd_positive(answer_num < 0 ? -answer_num : answer_num, answer_den);
    answer_num /= divisor;
    answer_den /= divisor;
    uint8_t staged[OUTPUT_BYTES];
    store_i64_le(staged, 0, answer_num);
    store_i64_le(staged, 8, answer_den);
    for (size_t i = 0; i < OUTPUT_BYTES; ++i) output[i] = staged[i];
    return OUTPUT_BYTES;
}
