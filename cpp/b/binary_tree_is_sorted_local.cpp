#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t missing_node = -2147483649LL;
constexpr std::size_t max_slots = 255;
}

extern "C" std::int64_t binary_tree_is_sorted_local(const std::int64_t *nodes, std::size_t length) {
    if (length == 0 || length > max_slots || nodes == nullptr || nodes[0] == missing_node) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        const auto value = nodes[index];
        if (value == missing_node) continue;
        if (value < -2147483648LL || value > 2147483647LL) return -1;
        if (index > 0) {
            const auto parent = (index - 1) / 2;
            if (nodes[parent] == missing_node) return -1;
            if ((index % 2 == 1 && value > nodes[parent]) ||
                (index % 2 == 0 && value < nodes[parent])) return 0;
        }
    }
    return 1;
}
