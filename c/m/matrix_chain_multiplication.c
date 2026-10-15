/* Minimum scalar multiplication cost for a matrix chain, using bottom-up DP. */
#include <stddef.h>
#include <stdint.h>

#define MAX_DIMS 65
#define MAX_DIMENSION 1000

int64_t matrix_chain_multiplication(const int64_t *dimensions, size_t length)
{
    if (length > MAX_DIMS) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (dimensions[index] < 1 || dimensions[index] > MAX_DIMENSION) return -1;
    }
    if (length < 2) return 0;

    const size_t matrix_count = length - 1;
    int64_t costs[MAX_DIMS * MAX_DIMS] = {0};
    for (size_t chain_length = 2; chain_length <= matrix_count; ++chain_length) {
        for (size_t start = 0; start + chain_length <= matrix_count; ++start) {
            const size_t end = start + chain_length - 1;
            int64_t best = INT64_MAX;
            for (size_t split = start; split < end; ++split) {
                const int64_t cost = costs[start * MAX_DIMS + split]
                    + costs[(split + 1) * MAX_DIMS + end]
                    + dimensions[start] * dimensions[split + 1] * dimensions[end + 1];
                if (cost < best) best = cost;
            }
            costs[start * MAX_DIMS + end] = best;
        }
    }
    return costs[matrix_count - 1];
}
