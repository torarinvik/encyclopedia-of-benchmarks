const MAX_NODES: usize = 100000;

export fn middle_of_linked_list(next: [*]const i64, length: usize) i64 {
    if (length > MAX_NODES) return -2;
    for (0..length) |index| {
        if (next[index] < -1 or next[index] >= @as(i64, @intCast(length))) return -2;
    }
    if (length == 0) return -1;

    var slow: i64 = 0;
    var fast: i64 = 0;
    while (fast >= 0) {
        const first = next[@intCast(fast)];
        if (first < 0) break;
        slow = next[@intCast(slow)];
        fast = next[@intCast(first)];
        if (slow == fast) return -2;
    }

    slow = 0;
    fast = 0;
    while (fast >= 0) {
        const first = next[@intCast(fast)];
        if (first < 0) break;
        slow = next[@intCast(slow)];
        fast = next[@intCast(first)];
    }
    return slow;
}
