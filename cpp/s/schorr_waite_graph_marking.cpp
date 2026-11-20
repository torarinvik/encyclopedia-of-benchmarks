#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t schorr_waite_graph_marking(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 4 || length > 66) return -1;

    const std::int64_t node_count_value = input[0];
    const std::int64_t root = input[1];
    if (node_count_value < 1 || node_count_value > 32) return -1;
    const std::size_t node_count = static_cast<std::size_t>(node_count_value);
    if (length != 2 + 2 * node_count || root < 0 || root >= node_count_value) {
        return -1;
    }

    std::array<std::int64_t, 32> left{};
    std::array<std::int64_t, 32> right{};
    std::array<bool, 32> marked{};
    std::array<bool, 32> phase{};
    for (std::size_t node = 0; node < node_count; ++node) {
        const std::int64_t left_child = input[2 + 2 * node];
        const std::int64_t right_child = input[3 + 2 * node];
        if (left_child < -1 || left_child >= node_count_value
            || right_child < -1 || right_child >= node_count_value) {
            return -1;
        }
        left[node] = left_child;
        right[node] = right_child;
    }

    std::int64_t parent = -1;
    std::int64_t current = root;
    std::int64_t temporary;
    while (parent != -1 || (current != -1 && !marked[static_cast<std::size_t>(current)])) {
        if (current == -1 || marked[static_cast<std::size_t>(current)]) {
            const std::size_t frame = static_cast<std::size_t>(parent);
            if (phase[frame]) {
                temporary = current;
                current = parent;
                parent = right[frame];
                right[frame] = temporary;
            } else {
                temporary = current;
                current = right[frame];
                right[frame] = left[frame];
                left[frame] = temporary;
                phase[frame] = true;
            }
        } else {
            temporary = parent;
            parent = current;
            current = left[static_cast<std::size_t>(parent)];
            left[static_cast<std::size_t>(parent)] = temporary;
            marked[static_cast<std::size_t>(parent)] = true;
            phase[static_cast<std::size_t>(parent)] = false;
        }
    }

    std::int64_t reachable = 0;
    for (std::size_t node = 0; node < node_count; ++node) {
        if (marked[node]) reachable |= INT64_C(1) << node;
    }
    return reachable;
}
