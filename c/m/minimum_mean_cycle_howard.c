#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MMC_MAX_VERTICES = 8, MMC_MAX_EDGES = 16, MMC_MAX_INPUT = 51, MMC_OUTPUT_BYTES = 16 };

typedef struct { size_t from; size_t to; int64_t weight; } MmcEdge;

static bool mmc_all_reachable(size_t n,
    const uint8_t adjacent[MMC_MAX_VERTICES][MMC_MAX_VERTICES], bool reverse)
{
    bool seen[MMC_MAX_VERTICES] = {false};
    size_t queue[MMC_MAX_VERTICES];
    size_t head = 0;
    size_t tail = 0;
    seen[0] = true;
    queue[tail++] = 0;
    while (head < tail) {
        const size_t u = queue[head++];
        for (size_t v = 0; v < n; ++v) {
            const bool has_edge = reverse ? adjacent[v][u] != 0 : adjacent[u][v] != 0;
            if (has_edge && !seen[v]) {
                seen[v] = true;
                queue[tail++] = v;
            }
        }
    }
    for (size_t v = 0; v < n; ++v) if (!seen[v]) return false;
    return true;
}

static int64_t mmc_gcd(int64_t a, int64_t b)
{
    while (b != 0) {
        const int64_t remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

static int mmc_compare_ratio(int64_t a_num, int64_t a_den,
                             int64_t b_num, int64_t b_den)
{
    const int64_t left = a_num * b_den;
    const int64_t right = b_num * a_den;
    return left < right ? -1 : left > right ? 1 : 0;
}

static int mmc_compare_appraisal(size_t left_edge, size_t right_edge,
    const MmcEdge edges[MMC_MAX_EDGES], const int64_t value_num[MMC_MAX_VERTICES],
    const int64_t value_den[MMC_MAX_VERTICES], const int64_t bias_num[MMC_MAX_VERTICES])
{
    const MmcEdge a = edges[left_edge];
    const MmcEdge b = edges[right_edge];
    int comparison = mmc_compare_ratio(value_num[a.to], value_den[a.to],
                                       value_num[b.to], value_den[b.to]);
    if (comparison != 0) return comparison;
    const int64_t a_bias = a.weight * value_den[a.to] - value_num[a.to] + bias_num[a.to];
    const int64_t b_bias = b.weight * value_den[b.to] - value_num[b.to] + bias_num[b.to];
    return mmc_compare_ratio(a_bias, value_den[a.to], b_bias, value_den[b.to]);
}

static bool mmc_evaluate_policy(size_t n, const MmcEdge edges[MMC_MAX_EDGES],
    const size_t policy[MMC_MAX_VERTICES], int64_t value_num[MMC_MAX_VERTICES],
    int64_t value_den[MMC_MAX_VERTICES], int64_t bias_num[MMC_MAX_VERTICES])
{
    bool assigned[MMC_MAX_VERTICES] = {false};
    for (size_t start = 0; start < n; ++start) {
        if (assigned[start]) continue;
        int local_position[MMC_MAX_VERTICES];
        for (size_t v = 0; v < n; ++v) local_position[v] = -1;
        size_t path[MMC_MAX_VERTICES];
        size_t path_length = 0;
        size_t vertex = start;
        while (!assigned[vertex] && local_position[vertex] < 0) {
            local_position[vertex] = (int)path_length;
            path[path_length++] = vertex;
            vertex = edges[policy[vertex]].to;
        }

        size_t prefix_length = path_length;
        if (!assigned[vertex]) {
            const size_t cycle_start = (size_t)local_position[vertex];
            const size_t cycle_length = path_length - cycle_start;
            int64_t cycle_weight = 0;
            size_t head_position = cycle_start;
            for (size_t i = cycle_start; i < path_length; ++i) {
                const size_t u = path[i];
                cycle_weight += edges[policy[u]].weight;
                if (path[i] < path[head_position]) head_position = i;
            }
            const int64_t absolute_weight = cycle_weight < 0 ? -cycle_weight : cycle_weight;
            const int64_t divisor = mmc_gcd(absolute_weight, (int64_t)cycle_length);
            const int64_t mean_num = cycle_weight / divisor;
            const int64_t mean_den = (int64_t)cycle_length / divisor;
            const size_t head = path[head_position];
            for (size_t i = cycle_start; i < path_length; ++i) {
                const size_t u = path[i];
                value_num[u] = mean_num;
                value_den[u] = mean_den;
                assigned[u] = true;
            }

            bias_num[head] = 0;
            size_t current_position = head_position;
            for (;;) {
                const size_t previous_position = current_position == cycle_start
                    ? path_length - 1 : current_position - 1;
                const size_t previous = path[previous_position];
                if (previous == head) break;
                bias_num[previous] = edges[policy[previous]].weight * mean_den
                    - mean_num + bias_num[path[current_position]];
                current_position = previous_position;
            }
            prefix_length = cycle_start;
        }

        for (size_t i = prefix_length; i > 0; --i) {
            const size_t u = path[i - 1];
            const size_t successor = edges[policy[u]].to;
            value_num[u] = value_num[successor];
            value_den[u] = value_den[successor];
            bias_num[u] = edges[policy[u]].weight * value_den[successor]
                - value_num[successor] + bias_num[successor];
            assigned[u] = true;
        }
    }
    return true;
}

static void mmc_store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t minimum_mean_cycle_howard(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MMC_MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MMC_MAX_VERTICES
        || input[1] < 1 || input[1] > MMC_MAX_EDGES) return -1;
    const size_t n = (size_t)input[0];
    const size_t edge_count = (size_t)input[1];
    if (edge_count > n * n || length != 2 + 3 * edge_count) return -1;

    MmcEdge edges[MMC_MAX_EDGES];
    uint8_t adjacent[MMC_MAX_VERTICES][MMC_MAX_VERTICES] = {{0}};
    uint8_t outgoing[MMC_MAX_VERTICES][MMC_MAX_EDGES] = {{0}};
    size_t degree[MMC_MAX_VERTICES] = {0};
    size_t policy[MMC_MAX_VERTICES] = {0};
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
        edges[i] = (MmcEdge){from, to, weight};
        outgoing[from][degree[from]++] = (uint8_t)i;
        if (degree[from] == 1) policy[from] = i;
    }
    if (!mmc_all_reachable(n, adjacent, false)
        || !mmc_all_reachable(n, adjacent, true)) return -1;
    if (output == NULL || capacity < MMC_OUTPUT_BYTES) return -2;

    size_t policy_limit = 1;
    for (size_t u = 0; u < n; ++u) policy_limit *= degree[u];
    int64_t value_num[MMC_MAX_VERTICES] = {0};
    int64_t value_den[MMC_MAX_VERTICES] = {1};
    int64_t bias_num[MMC_MAX_VERTICES] = {0};
    bool converged = false;
    for (size_t iteration = 0; iteration < policy_limit; ++iteration) {
        if (!mmc_evaluate_policy(n, edges, policy, value_num, value_den, bias_num)) return -1;
        size_t improved[MMC_MAX_VERTICES];
        bool changed = false;
        for (size_t u = 0; u < n; ++u) {
            size_t best = policy[u];
            for (size_t j = 0; j < degree[u]; ++j) {
                const size_t candidate = outgoing[u][j];
                if (mmc_compare_appraisal(candidate, best, edges,
                        value_num, value_den, bias_num) < 0) best = candidate;
            }
            improved[u] = best;
            if (best != policy[u]) changed = true;
        }
        if (!changed) {
            converged = true;
            break;
        }
        for (size_t u = 0; u < n; ++u) policy[u] = improved[u];
    }
    if (!converged) return -1;

    size_t best_vertex = 0;
    for (size_t v = 1; v < n; ++v) {
        if (mmc_compare_ratio(value_num[v], value_den[v],
                              value_num[best_vertex], value_den[best_vertex]) < 0) {
            best_vertex = v;
        }
    }
    int64_t answer_num = value_num[best_vertex];
    int64_t answer_den = value_den[best_vertex];
    const int64_t divisor = mmc_gcd(answer_num < 0 ? -answer_num : answer_num, answer_den);
    answer_num /= divisor;
    answer_den /= divisor;
    uint8_t staged[MMC_OUTPUT_BYTES];
    mmc_store_i64_le(staged, 0, answer_num);
    mmc_store_i64_le(staged, 8, answer_den);
    for (size_t i = 0; i < MMC_OUTPUT_BYTES; ++i) output[i] = staged[i];
    return MMC_OUTPUT_BYTES;
}
