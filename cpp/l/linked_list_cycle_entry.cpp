/* Floyd cycle-entry search over a portable successor-index representation. */
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

// Returns the cycle-entry node index, -1 if acyclic, and -2 for malformed input.
extern "C" std::int64_t linked_list_cycle_entry(const std::int64_t *next,
                                                 std::size_t length) noexcept {
    if (!valid_successors(next, length)) return -2;
    if (length == 0) return -1;
    std::int64_t slow = 0, fast = 0;
    bool meeting = false;
    while (fast >= 0) {
        const auto first = successor(next, fast);
        if (first < 0) break;
        slow = successor(next, slow);
        fast = successor(next, first);
        if (slow == fast) { meeting = true; break; }
    }
    if (!meeting) return -1;
    std::int64_t entry = 0;
    while (entry != slow) {
        entry = successor(next, entry);
        slow = successor(next, slow);
    }
    return entry;
}
