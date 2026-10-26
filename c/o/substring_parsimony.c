#include <stddef.h>
#include <stdint.h>

#define MAX_STATES 4
#define MAX_INPUT 26
#define MAX_ASSIGNMENTS 1024
#define MAX_OUTPUT_WORDS (2 + 5 * MAX_ASSIGNMENTS)
#define INF 1000000

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t substring_parsimony(const int64_t *input, size_t length,
                            uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 10 || length > MAX_INPUT) return -1;
    const int64_t q_raw = input[0], threshold = input[1];
    if (q_raw < 1 || q_raw > MAX_STATES || threshold < 0 || threshold > 36) return -1;
    const size_t q = (size_t)q_raw;
    if (length != 9 + q * q) return -1;

    int64_t child[2][2] = {{input[2], input[3]}, {input[4], input[5]}};
    for (size_t node = 0; node < 2; ++node) {
        if (child[node][0] < 1 || child[node][0] > 4 || child[node][1] < 1 || child[node][1] > 4
            || child[node][0] == child[node][1]) return -1;
    }
    int64_t root_leaf = -1;
    if (child[0][0] == 1) root_leaf = child[0][1];
    else if (child[0][1] == 1) root_leaf = child[0][0];
    if (root_leaf < 2 || root_leaf > 4) return -1;
    if (child[1][0] < 2 || child[1][0] > 4 || child[1][1] < 2 || child[1][1] > 4
        || child[1][0] == root_leaf || child[1][1] == root_leaf) return -1;
    if (child[1][0] == child[1][1]) return -1;
    for (int64_t leaf = 2; leaf <= 4; ++leaf) {
        if (leaf == root_leaf) continue;
        if (child[1][0] != leaf && child[1][1] != leaf) return -1;
    }

    int64_t masks[3];
    const uint64_t universe = (UINT64_C(1) << q) - 1;
    for (size_t leaf = 0; leaf < 3; ++leaf) {
        masks[leaf] = input[6 + leaf];
        if (masks[leaf] <= 0 || (uint64_t)masks[leaf] > universe) return -1;
    }
    int64_t distance[MAX_STATES][MAX_STATES] = {{0}};
    for (size_t i = 0; i < q; ++i) {
        for (size_t j = 0; j < q; ++j) {
            const int64_t value = input[9 + i * q + j];
            if (value < 0 || value > 9 || (i == j && value != 0) || (i != j && value == 0)) return -1;
            distance[i][j] = value;
            if (distance[i][j] != input[9 + j * q + i]) return -1;
        }
    }
    for (size_t i = 0; i < q; ++i)
        for (size_t j = 0; j < q; ++j)
            for (size_t k = 0; k < q; ++k)
                if (distance[i][k] > distance[i][j] + distance[j][k]) return -1;

    int64_t dp[5][MAX_STATES];
    for (size_t node = 0; node < 5; ++node)
        for (size_t state = 0; state < q; ++state) dp[node][state] = INF;
    for (size_t leaf = 2; leaf <= 4; ++leaf)
        for (size_t state = 0; state < q; ++state)
            if (((uint64_t)masks[leaf - 2] & (UINT64_C(1) << state)) != 0) dp[leaf][state] = 0;
    for (int node = 1; node >= 0; --node) {
        for (size_t state = 0; state < q; ++state) {
            int64_t total = 0;
            for (size_t slot = 0; slot < 2; ++slot) {
                const size_t descendant = (size_t)child[node][slot];
                int64_t best = INF;
                for (size_t other = 0; other < q; ++other) {
                    const int64_t candidate = dp[descendant][other] + distance[state][other];
                    if (candidate < best) best = candidate;
                }
                total += best;
            }
            dp[node][state] = total;
        }
    }
    int64_t optimum = INF;
    for (size_t state = 0; state < q; ++state) if (dp[0][state] < optimum) optimum = dp[0][state];
    if (optimum >= INF) return -1;

    int64_t staged[MAX_OUTPUT_WORDS] = {0};
    staged[0] = optimum;
    size_t words = 2;
    if (optimum <= threshold) {
        for (size_t x0 = 0; x0 < q; ++x0) {
            for (size_t x1 = 0; x1 < q; ++x1) {
                for (size_t x2 = 0; x2 < q; ++x2) {
                    if (((uint64_t)masks[0] & (UINT64_C(1) << x2)) == 0) continue;
                    for (size_t x3 = 0; x3 < q; ++x3) {
                        if (((uint64_t)masks[1] & (UINT64_C(1) << x3)) == 0) continue;
                        for (size_t x4 = 0; x4 < q; ++x4) {
                            if (((uint64_t)masks[2] & (UINT64_C(1) << x4)) == 0) continue;
                            const size_t label[5] = {x0, x1, x2, x3, x4};
                            int64_t score = 0;
                            for (size_t node = 0; node < 2; ++node)
                                for (size_t slot = 0; slot < 2; ++slot)
                                    score += distance[label[node]][label[(size_t)child[node][slot]]];
                            if (score == optimum) {
                                for (size_t node = 0; node < 5; ++node) staged[words++] = (int64_t)label[node];
                            }
                        }
                    }
                }
            }
        }
    }
    staged[1] = (int64_t)((words - 2) / 5);
    const size_t bytes = words * 8;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t word = 0; word < words; ++word) store_i64_le(output, word * 8, staged[word]);
    return (int64_t)bytes;
}
