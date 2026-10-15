/* Return the second middle node's index in a successor-index list. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_nodes = 100000; }

extern "C" std::int64_t middle_of_linked_list(const std::int64_t *next,
        std::size_t length) noexcept {
    if (length > max_nodes || (length != 0 && next == nullptr)) return -2;
    for (std::size_t index = 0; index < length; ++index)
        if (next[index] < -1 || next[index] >= static_cast<std::int64_t>(length)) return -2;
    if (length == 0) return -1;

    std::int64_t slow = 0, fast = 0;
    while (fast >= 0) {
        const auto first = next[static_cast<std::size_t>(fast)];
        if (first < 0) break;
        slow = next[static_cast<std::size_t>(slow)];
        fast = next[static_cast<std::size_t>(first)];
        if (slow == fast) return -2;
    }

    slow = 0;
    fast = 0;
    while (fast >= 0) {
        const auto first = next[static_cast<std::size_t>(fast)];
        if (first < 0) break;
        slow = next[static_cast<std::size_t>(slow)];
        fast = next[static_cast<std::size_t>(first)];
    }
    return slow;
}
