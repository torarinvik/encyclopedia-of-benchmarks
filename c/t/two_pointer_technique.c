#include <stddef.h>
#include <stdint.h>

static int64_t next_node(int64_t node, int64_t n, int64_t cycle_target) {
    if (node < 0) return -1;
    return node + 1 < n ? node + 1 : cycle_target;
}

int64_t two_pointer_technique(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > 132) return -1;
    const int64_t op = input[0], n = input[1], cycle_target = input[2], k = input[3];
    if (n < 0 || n > 128 || length != 4 + (size_t)n) return -1;
    if ((n == 0 && cycle_target != -1) || (n > 0 && (cycle_target < -1 || cycle_target >= n))) return -1;
    for (size_t i = 0; i < (size_t)n; ++i) if (input[4 + i] < -1000000 || input[4 + i] > 1000000) return -1;

    if (op == 0) {
        if (k != 0) return -1;
        int64_t slow = n == 0 ? -1 : 0, fast = slow;
        while (fast != -1) {
            slow = next_node(slow, n, cycle_target);
            fast = next_node(fast, n, cycle_target);
            if (fast != -1) fast = next_node(fast, n, cycle_target);
            if (slow == -1 || fast == -1) break;
            if (slow == fast) return 1;
        }
        return 0;
    }
    if (op == 1) {
        if (cycle_target != -1 || k != 0) return -1;
        if (n == 0) return -2;
        int64_t slow = 0, fast = 0;
        while (fast != -1) {
            fast = next_node(fast, n, cycle_target);
            if (fast == -1) break;
            fast = next_node(fast, n, cycle_target);
            slow = next_node(slow, n, cycle_target);
        }
        return input[4 + (size_t)slow] + 1000001;
    }
    if (op == 2) {
        if (cycle_target != -1 || k < 1 || k > n) return -1;
        int64_t lead = 0, lag = 0;
        for (int64_t i = 0; i < k; ++i) lead = next_node(lead, n, cycle_target);
        while (lead != -1) { lead = next_node(lead, n, cycle_target); lag = next_node(lag, n, cycle_target); }
        return input[4 + (size_t)lag] + 3000002;
    }
    return -1;
}
