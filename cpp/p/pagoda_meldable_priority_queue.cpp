/* Pagoda priority queue with two parent/extreme-leaf links per node. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_queues = 8;
constexpr int max_operations = 64;
constexpr std::int64_t nil = -1;

int branch_stack(std::int64_t root, bool right_branch, std::int64_t node_count,
                 const std::int64_t* leftmost, const std::int64_t* rightmost,
                 std::int64_t* stack) noexcept {
    std::int64_t node = right_branch ? rightmost[root] : leftmost[root];
    if (node < 0 || node >= node_count) return -1;
    int count = 0;
    while (count < node_count) {
        stack[count++] = node;
        if (node == root) return count;
        node = right_branch ? rightmost[node] : leftmost[node];
        if (node < 0 || node >= node_count) return -1;
    }
    return -1;
}

std::int64_t pagoda_meld(std::int64_t g_root, std::int64_t d_root,
                         std::int64_t node_count, const std::int64_t* keys,
                         std::int64_t* leftmost, std::int64_t* rightmost) noexcept {
    if (g_root < 0) return d_root;
    if (d_root < 0) return g_root;

    std::int64_t g_branch[max_operations];
    std::int64_t d_branch[max_operations];
    const int g_count = branch_stack(g_root, true, node_count, leftmost, rightmost, g_branch);
    const int d_count = branch_stack(d_root, false, node_count, leftmost, rightmost, d_branch);
    if (g_count < 1 || d_count < 1) return -2;

    int gi = 0, di = 0;
    std::int64_t central = nil, central_left = nil, central_right = nil;
    while (gi < g_count || di < d_count) {
        const bool take_g = di >= d_count ||
                            (gi < g_count && keys[g_branch[gi]] > keys[d_branch[di]]);
        std::int64_t node;
        std::int64_t kept_extreme;
        if (take_g) {
            node = g_branch[gi++];
            kept_extreme = leftmost[node];
        } else {
            node = d_branch[di++];
            kept_extreme = rightmost[node];
        }

        if (central >= 0) {
            if (take_g) {
                rightmost[central] = node;
                leftmost[central] = central_left == central ? nil : central_left;
            } else {
                leftmost[central] = node;
                rightmost[central] = central_right == central ? nil : central_right;
            }
        }

        const std::int64_t new_left = take_g
            ? (kept_extreme < 0 ? node : kept_extreme)
            : (central >= 0 ? central_left : node);
        const std::int64_t new_right = take_g
            ? (central >= 0 ? central_right : node)
            : (kept_extreme < 0 ? node : kept_extreme);
        leftmost[node] = new_left;
        rightmost[node] = new_right;
        central = node;
        central_left = new_left;
        central_right = new_right;
    }
    return central;
}

std::int64_t pagoda_extract_min(std::int64_t root, std::int64_t node_count,
                                const std::int64_t* keys, std::int64_t* leftmost,
                                std::int64_t* rightmost) noexcept {
    const std::int64_t old_leftmost = leftmost[root];
    const std::int64_t old_rightmost = rightmost[root];
    std::int64_t left_child = nil, right_child = nil;
    if (old_leftmost != root) {
        std::int64_t node = old_leftmost;
        std::int64_t steps = 0;
        while (node >= 0 && node < node_count && leftmost[node] != root && steps++ < node_count)
            node = leftmost[node];
        if (node < 0 || node >= node_count || leftmost[node] != root) return -2;
        left_child = node;
    }
    if (old_rightmost != root) {
        std::int64_t node = old_rightmost;
        std::int64_t steps = 0;
        while (node >= 0 && node < node_count && rightmost[node] != root && steps++ < node_count)
            node = rightmost[node];
        if (node < 0 || node >= node_count || rightmost[node] != root) return -2;
        right_child = node;
    }

    if (left_child >= 0) {
        leftmost[left_child] = old_leftmost;
        if (rightmost[left_child] < 0) rightmost[left_child] = left_child;
    }
    if (right_child >= 0) {
        rightmost[right_child] = old_rightmost;
        if (leftmost[right_child] < 0) leftmost[right_child] = right_child;
    }
    const std::int64_t new_root = pagoda_meld(right_child, left_child, node_count,
                                              keys, leftmost, rightmost);
    leftmost[root] = nil;
    rightmost[root] = nil;
    return new_root;
}
} // namespace

extern "C" std::int64_t pagoda_meldable_priority_queue(const std::int64_t* input,
                                                        std::size_t length) {
    if (input == nullptr || length < 2 || length > 259) return -1;
    const std::int64_t raw_queues = input[0], raw_operations = input[1];
    if (raw_queues < 1 || raw_queues > max_queues || raw_operations < 0 ||
        raw_operations > max_operations || length != static_cast<std::size_t>(2 + 4 * raw_operations) ||
        length > 258) return -1;

    std::int64_t keys[max_operations]{};
    std::int64_t leftmost[max_operations];
    std::int64_t rightmost[max_operations];
    std::int64_t roots[max_queues];
    for (int i = 0; i < max_operations; ++i) leftmost[i] = rightmost[i] = nil;
    for (int i = 0; i < max_queues; ++i) roots[i] = nil;

    std::int64_t node_count = 0, result = 0;
    for (std::int64_t op = 0; op < raw_operations; ++op) {
        const std::size_t offset = static_cast<std::size_t>(2 + 4 * op);
        const std::int64_t opcode = input[offset];
        const std::int64_t first = input[offset + 1];
        const std::int64_t second = input[offset + 2];
        const std::int64_t priority = input[offset + 3];
        if (opcode == 1) {
            if (first < 0 || first >= raw_queues || second != 0 || priority < -1000 ||
                priority > 1000 || node_count >= max_operations) return -1;
            for (std::int64_t i = 0; i < node_count; ++i)
                if (keys[i] == priority) return -1;
            const std::int64_t node = node_count++;
            keys[node] = priority;
            leftmost[node] = rightmost[node] = node;
            const std::int64_t merged = pagoda_meld(roots[first], node, node_count,
                                                     keys, leftmost, rightmost);
            if (merged < 0) return -1;
            roots[first] = merged;
        } else if (opcode == 2) {
            if (first < 0 || first >= raw_queues || second < 0 || second >= raw_queues ||
                first == second || priority != 0) return -1;
            const std::int64_t merged = pagoda_meld(roots[first], roots[second], node_count,
                                                    keys, leftmost, rightmost);
            if (merged == -2) return -1;
            roots[first] = merged;
            roots[second] = nil;
        } else if (opcode == 3 || opcode == 4) {
            if (first < 0 || first >= raw_queues || second != 0 || priority != 0 ||
                roots[first] < 0) return -1;
            const std::int64_t root = roots[first];
            result += (op + 1) * (keys[root] + 1001);
            if (opcode == 4) {
                const std::int64_t new_root = pagoda_extract_min(root, node_count,
                                                                 keys, leftmost, rightmost);
                if (new_root == -2) return -1;
                roots[first] = new_root;
            }
        } else return -1;
    }
    return result;
}
