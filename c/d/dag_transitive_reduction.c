/* Count cover arcs using non-reflexive transitive closure. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 28, MAX_LENGTH = 58 };

int64_t dag_transitive_reduction(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_LENGTH + 1) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_M) return -1;
    const size_t n = (size_t)input[0];
    const size_t m = (size_t)input[1];
    if (length != 2 + 2 * m) return -1;

    uint16_t outgoing[MAX_N] = {0};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t tail_value = input[2 + 2 * edge];
        const int64_t head_value = input[3 + 2 * edge];
        if (tail_value < 0 || head_value < 0 || (uint64_t)tail_value >= n ||
            (uint64_t)head_value >= n || tail_value == head_value) return -1;
        const size_t tail = (size_t)tail_value, head = (size_t)head_value;
        const uint16_t bit = (uint16_t)(1u << head);
        if ((outgoing[tail] & bit) != 0) return -1;
        outgoing[tail] |= bit;
    }

    uint16_t reach[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) reach[vertex] = outgoing[vertex];
    for (size_t middle = 0; middle < n; ++middle) {
        const uint16_t middle_bit = (uint16_t)(1u << middle);
        for (size_t source = 0; source < n; ++source)
            if ((reach[source] & middle_bit) != 0) reach[source] |= reach[middle];
    }
    for (size_t vertex = 0; vertex < n; ++vertex)
        if ((reach[vertex] & (uint16_t)(1u << vertex)) != 0) return -1;

    int64_t retained = 0;
    for (size_t edge = 0; edge < m; ++edge) {
        const size_t tail = (size_t)input[2 + 2 * edge];
        const size_t head = (size_t)input[3 + 2 * edge];
        bool redundant = false;
        for (size_t middle = 0; middle < n; ++middle) {
            if (middle != tail && middle != head &&
                (outgoing[tail] & (uint16_t)(1u << middle)) != 0 &&
                (reach[middle] & (uint16_t)(1u << head)) != 0) {
                redundant = true;
                break;
            }
        }
        if (!redundant) ++retained;
    }
    return retained;
}
