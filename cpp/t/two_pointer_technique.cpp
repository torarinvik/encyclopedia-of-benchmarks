#include <cstddef>
#include <cstdint>

namespace {
std::int64_t next_node(std::int64_t node, std::int64_t n, std::int64_t cycleTarget) noexcept {
    if (node < 0) return -1;
    return node + 1 < n ? node + 1 : cycleTarget;
}
}

extern "C" std::int64_t two_pointer_technique(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 4 || length > 132) return -1;
    const auto op = input[0], n = input[1], cycleTarget = input[2], k = input[3];
    if (n < 0 || n > 128 || length != 4 + static_cast<std::size_t>(n)) return -1;
    if ((n == 0 && cycleTarget != -1) || (n > 0 && (cycleTarget < -1 || cycleTarget >= n))) return -1;
    for (std::size_t i = 0; i < static_cast<std::size_t>(n); ++i)
        if (input[4 + i] < -1000000 || input[4 + i] > 1000000) return -1;

    if (op == 0) {
        if (k != 0) return -1;
        std::int64_t slow = n == 0 ? -1 : 0, fast = slow;
        while (fast != -1) {
            slow = next_node(slow, n, cycleTarget);
            fast = next_node(fast, n, cycleTarget);
            if (fast != -1) fast = next_node(fast, n, cycleTarget);
            if (slow == -1 || fast == -1) break;
            if (slow == fast) return 1;
        }
        return 0;
    }
    if (op == 1) {
        if (cycleTarget != -1 || k != 0) return -1;
        if (n == 0) return -2;
        std::int64_t slow = 0, fast = 0;
        while (fast != -1) {
            fast = next_node(fast, n, cycleTarget);
            if (fast == -1) break;
            fast = next_node(fast, n, cycleTarget);
            slow = next_node(slow, n, cycleTarget);
        }
        return input[4 + static_cast<std::size_t>(slow)] + 1000001;
    }
    if (op == 2) {
        if (cycleTarget != -1 || k < 1 || k > n) return -1;
        std::int64_t lead = 0, lag = 0;
        for (std::int64_t i = 0; i < k; ++i) lead = next_node(lead, n, cycleTarget);
        while (lead != -1) { lead = next_node(lead, n, cycleTarget); lag = next_node(lag, n, cycleTarget); }
        return input[4 + static_cast<std::size_t>(lag)] + 3000002;
    }
    return -1;
}
