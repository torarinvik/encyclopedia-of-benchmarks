/* Minimum scalar multiplication cost for a matrix chain, using bottom-up DP. */
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_dims = 65;
constexpr std::int64_t max_dimension = 1000;
}

extern "C" std::int64_t matrix_chain_multiplication(const std::int64_t *dimensions,
                                                     std::size_t length) noexcept
{
    if (length > max_dims) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (dimensions[index] < 1 || dimensions[index] > max_dimension) return -1;
    }
    if (length < 2) return 0;

    const std::size_t matrix_count = length - 1;
    std::int64_t costs[max_dims * max_dims] = {};
    for (std::size_t chain_length = 2; chain_length <= matrix_count; ++chain_length) {
        for (std::size_t start = 0; start + chain_length <= matrix_count; ++start) {
            const std::size_t end = start + chain_length - 1;
            std::int64_t best = std::numeric_limits<std::int64_t>::max();
            for (std::size_t split = start; split < end; ++split) {
                const std::int64_t cost = costs[start * max_dims + split]
                    + costs[(split + 1) * max_dims + end]
                    + dimensions[start] * dimensions[split + 1] * dimensions[end + 1];
                if (cost < best) best = cost;
            }
            costs[start * max_dims + end] = best;
        }
    }
    return costs[matrix_count - 1];
}
