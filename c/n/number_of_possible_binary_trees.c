/* Count labeled binary trees using the pinned Catalan-times-factorial formula. */
#include <stdint.h>

int64_t number_of_possible_binary_trees(int64_t node_count)
{
    if (node_count < 1 || node_count > 14) return -1;
    int64_t binomial = 1;
    for (int64_t index = 0; index < node_count; ++index) {
        binomial *= 2 * node_count - index;
        binomial /= index + 1;
    }
    const int64_t catalan = binomial / (node_count + 1);
    int64_t factorial = 1;
    for (int64_t factor = 2; factor <= node_count; ++factor) factorial *= factor;
    return catalan * factorial;
}
