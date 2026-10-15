/* Floyd cycle detection over a portable successor-index representation. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes = 100000;
bool valid_successors(const std::int64_t *next, std::size_t length) noexcept {
    if (length > max_nodes || (length != 0 && next == nullptr)) return false;
    for (std::size_t i = 0; i < length; ++i)
        if (next[i] < -1 || next[i] >= static_cast<std::int64_t>(length)) return false;
    return true;
}
std::int64_t successor(const std::int64_t *next, std::int64_t node) noexcept {
    return node < 0 ? -1 : next[static_cast<std::size_t>(node)];
}
}

// Input is next-node indices; -1 means null and node 0 is the head.
// Returns 1 for a cycle, 0 for an acyclic list, and -1 for malformed input.
extern "C" std::int64_t linked_list_has_cycle(const std::int64_t *next,
                                               std::size_t length) noexcept {
    if (!valid_successors(next, length)) return -1;
    if (length == 0) return 0;
    std::int64_t slow = 0, fast = 0;
    while (fast >= 0) {
        const auto first = successor(next, fast);
        if (first < 0) break;
        slow = successor(next, slow);
        fast = successor(next, first);
        if (slow == fast) return 1;
    }
    return 0;
}
