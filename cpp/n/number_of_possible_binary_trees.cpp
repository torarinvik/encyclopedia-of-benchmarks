// Count labeled binary trees using the pinned Catalan-times-factorial formula.
#include <cstdint>

extern "C" std::int64_t number_of_possible_binary_trees(std::int64_t node_count) noexcept {
    if (node_count < 1 || node_count > 14) return -1;
    std::int64_t binomial = 1;
    for (std::int64_t index = 0; index < node_count; ++index) {
        binomial *= 2 * node_count - index;
        binomial /= index + 1;
    }
    const auto catalan = binomial / (node_count + 1);
    std::int64_t factorial = 1;
    for (std::int64_t factor = 2; factor <= node_count; ++factor) factorial *= factor;
    return catalan * factorial;
}
