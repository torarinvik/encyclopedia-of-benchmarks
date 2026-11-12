#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_STATES (1u << MAX_N)
#define MAX_INPUT_VALUES (2 + 3 * (MAX_N * (MAX_N - 1) / 2) + 1)
#define MAX_WEIGHT INT64_C(1000000)
#define MAX_OUTPUT_BYTES (8 * (2 + MAX_N))

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t general_weighted_matching(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > MAX_N || m_value < 0 ||
        m_value > n_value * (n_value - 1) / 2) return -1;
    const int n = (int)n_value, m = (int)m_value;
    if (length != (size_t)(2 + 3 * m)) return -1;

    int64_t weight[MAX_N][MAX_N] = {{0}};
    uint8_t present[MAX_N][MAX_N] = {{0}};
    size_t cursor = 2;
    for (int edge = 0; edge < m; ++edge) {
        int64_t u_value = input[cursor++];
        int64_t v_value = input[cursor++];
        int64_t edge_weight = input[cursor++];
        if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n ||
            u_value == v_value || edge_weight < 1 || edge_weight > MAX_WEIGHT) return -1;
        int u = (int)u_value, v = (int)v_value;
        if (present[u][v]) return -1;
        present[u][v] = present[v][u] = 1;
        weight[u][v] = weight[v][u] = edge_weight;
    }

    int64_t dp[MAX_STATES] = {0};
    const uint32_t state_count = UINT32_C(1) << n;
    for (uint32_t mask = 1; mask < state_count; ++mask) {
        uint32_t bit = mask & (~mask + 1u);
        int vertex = 0;
        while ((bit >> vertex) != 1u) ++vertex;
        const uint32_t remainder = mask ^ bit;
        dp[mask] = dp[remainder];
        for (int partner = vertex + 1; partner < n; ++partner) {
            const uint32_t partner_bit = UINT32_C(1) << partner;
            if ((remainder & partner_bit) == 0 || !present[vertex][partner]) continue;
            const int64_t candidate = weight[vertex][partner] + dp[remainder ^ partner_bit];
            if (candidate > dp[mask]) dp[mask] = candidate;
        }
    }

    int64_t output_words[2 + MAX_N];
    int pair_count = 0;
    uint32_t mask = state_count - 1u;
    while (mask != 0) {
        const uint32_t bit = mask & (~mask + 1u);
        int vertex = 0;
        while ((bit >> vertex) != 1u) ++vertex;
        const uint32_t remainder = mask ^ bit;
        if (dp[mask] == dp[remainder]) {
            mask = remainder;
            continue;
        }
        int selected = -1;
        for (int partner = vertex + 1; partner < n; ++partner) {
            const uint32_t partner_bit = UINT32_C(1) << partner;
            if ((remainder & partner_bit) != 0 && present[vertex][partner] &&
                weight[vertex][partner] + dp[remainder ^ partner_bit] == dp[mask]) {
                selected = partner;
                break;
            }
        }
        if (selected < 0) return -1;
        output_words[2 + 2 * pair_count] = vertex;
        output_words[3 + 2 * pair_count] = selected;
        ++pair_count;
        mask = remainder ^ (UINT32_C(1) << selected);
    }

    output_words[0] = pair_count;
    output_words[1] = dp[state_count - 1u];
    const size_t output_bytes = (size_t)(2 + 2 * pair_count) * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t word = 0; word < 2 + 2 * (size_t)pair_count; ++word)
        store_i64_le(output, 8 * word, output_words[word]);
    return (int64_t)output_bytes;
}
