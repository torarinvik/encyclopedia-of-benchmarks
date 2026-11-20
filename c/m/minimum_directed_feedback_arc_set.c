/* Exact subset DP for minimum directed feedback arc set. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 8, MAX_EDGES = 56, MAX_LENGTH = 114, MAX_STATES = 256 };

int64_t minimum_directed_feedback_arc_set(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_LENGTH + 1) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES) return -1;
    const size_t vertices = (size_t)input[0];
    const size_t edges = (size_t)input[1];
    if (length != 2 + 2 * edges) return -1;

    uint16_t outgoing[MAX_VERTICES] = {0};
    for (size_t edge = 0; edge < edges; ++edge) {
        const int64_t tail_value = input[2 + 2 * edge];
        const int64_t head_value = input[3 + 2 * edge];
        if (tail_value < 0 || head_value < 0 ||
            (uint64_t)tail_value >= vertices || (uint64_t)head_value >= vertices ||
            tail_value == head_value) return -1;
        const size_t tail = (size_t)tail_value;
        const size_t head = (size_t)head_value;
        const uint16_t bit = (uint16_t)(1u << head);
        if ((outgoing[tail] & bit) != 0) return -1;
        outgoing[tail] |= bit;
    }

    const size_t full = ((size_t)1 << vertices) - 1;
    int64_t dp[MAX_STATES];
    for (size_t mask = 0; mask < MAX_STATES; ++mask) dp[mask] = INT64_MAX / 4;
    dp[0] = 0;
    for (size_t prefix = 0; prefix <= full; ++prefix) {
        if (dp[prefix] == INT64_MAX / 4) continue;
        for (size_t vertex = 0; vertex < vertices; ++vertex) {
            const size_t bit = (size_t)1 << vertex;
            if ((prefix & bit) != 0) continue;
            int64_t backward = 0;
            for (size_t prior = 0; prior < vertices; ++prior)
                if ((prefix & ((size_t)1 << prior)) != 0 &&
                    (outgoing[vertex] & (uint16_t)(1u << prior)) != 0) ++backward;
            const size_t target = prefix | bit;
            const int64_t candidate = dp[prefix] + backward;
            if (candidate < dp[target]) dp[target] = candidate;
        }
    }
    return dp[full];
}
