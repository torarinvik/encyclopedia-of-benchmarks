fn nextNode(node: i64, n: i64, cycle_target: i64) i64 {
    if (node < 0) return -1;
    if (node + 1 < n) return node + 1;
    return cycle_target;
}

export fn two_pointer_technique(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > 132) return -1;
    const values = input.?;
    const op = values[0];
    const n = values[1];
    const cycle_target = values[2];
    const k = values[3];
    if (n < 0 or n > 128 or length != 4 + @as(usize, @intCast(n))) return -1;
    if ((n == 0 and cycle_target != -1) or (n > 0 and (cycle_target < -1 or cycle_target >= n))) return -1;
    const count: usize = @intCast(n);
    for (0..count) |i| if (values[4 + i] < -1000000 or values[4 + i] > 1000000) return -1;

    if (op == 0) {
        if (k != 0) return -1;
        var slow: i64 = if (n == 0) -1 else 0;
        var fast = slow;
        while (fast != -1) {
            slow = nextNode(slow, n, cycle_target);
            fast = nextNode(fast, n, cycle_target);
            if (fast != -1) fast = nextNode(fast, n, cycle_target);
            if (slow == -1 or fast == -1) break;
            if (slow == fast) return 1;
        }
        return 0;
    }
    if (op == 1) {
        if (cycle_target != -1 or k != 0) return -1;
        if (n == 0) return -2;
        var slow: i64 = 0;
        var fast: i64 = 0;
        while (fast != -1) {
            fast = nextNode(fast, n, cycle_target);
            if (fast == -1) break;
            fast = nextNode(fast, n, cycle_target);
            slow = nextNode(slow, n, cycle_target);
        }
        return values[4 + @as(usize, @intCast(slow))] + 1000001;
    }
    if (op == 2) {
        if (cycle_target != -1 or k < 1 or k > n) return -1;
        var lead: i64 = 0;
        var lag: i64 = 0;
        var i: i64 = 0;
        while (i < k) : (i += 1) lead = nextNode(lead, n, cycle_target);
        while (lead != -1) {
            lead = nextNode(lead, n, cycle_target);
            lag = nextNode(lag, n, cycle_target);
        }
        return values[4 + @as(usize, @intCast(lag))] + 3000002;
    }
    return -1;
}
