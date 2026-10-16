#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 100000
#define INVALID_RESULT (-1.0e300)

double density(const int64_t *values, size_t length) {
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t nodes = values[0];
    const int64_t edges = values[1];
    const int64_t directed = values[2];
    if (nodes < 2 || nodes > MAX_NODES || (directed != 0 && directed != 1)) return INVALID_RESULT;
    const int64_t max_edges = directed == 1 ? nodes * (nodes - 1) : nodes * (nodes - 1) / 2;
    if (edges < 0 || edges > max_edges) return INVALID_RESULT;
    const double factor = directed == 1 ? 1.0 : 2.0;
    return (factor * (double)edges) / ((double)nodes * (double)(nodes - 1));
}
