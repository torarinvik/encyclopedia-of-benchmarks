module two_pointer_technique;

fn long next_node(long node, long n, long cycle_target) {
    if (node < 0) return -1;
    return node + 1 < n ? node + 1 : cycle_target;
}

fn long two_pointer_technique(long* input, usz length) @export("two_pointer_technique") {
    if (input == null || length < 4 || length > 132) return -1;
    long op = input[0], n = input[1], cycle_target = input[2], k = input[3];
    if (n < 0 || n > 128 || length != 4 + (usz)n) return -1;
    if ((n == 0 && cycle_target != -1) || (n > 0 && (cycle_target < -1 || cycle_target >= n))) return -1;
    for (usz i = 0; i < (usz)n; i++) if (input[4 + i] < -1000000 || input[4 + i] > 1000000) return -1;

    if (op == 0) {
        if (k != 0) return -1;
        long slow = n == 0 ? -1 : 0, fast = slow;
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
        long slow = 0, fast = 0;
        while (fast != -1) {
            fast = next_node(fast, n, cycle_target);
            if (fast == -1) break;
            fast = next_node(fast, n, cycle_target);
            slow = next_node(slow, n, cycle_target);
        }
        return input[4 + (usz)slow] + 1000001;
    }
    if (op == 2) {
        if (cycle_target != -1 || k < 1 || k > n) return -1;
        long lead = 0, lag = 0;
        for (long i = 0; i < k; i++) lead = next_node(lead, n, cycle_target);
        while (lead != -1) { lead = next_node(lead, n, cycle_target); lag = next_node(lag, n, cycle_target); }
        return input[4 + (usz)lag] + 3000002;
    }
    return -1;
}
