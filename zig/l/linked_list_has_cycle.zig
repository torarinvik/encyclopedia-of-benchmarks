/// Floyd cycle detection over a portable successor-index representation.
const MAX_NODES: usize = 100_000;

fn validSuccessors(next: [*]const i64, length: usize) bool {
    if (length > MAX_NODES) return false;
    for (0..length) |index| {
        if (next[index] < -1 or next[index] >= @as(i64, @intCast(length))) return false;
    }
    return true;
}

fn successor(next: [*]const i64, node: i64) i64 {
    if (node < 0) return -1;
    return next[@intCast(node)];
}

/// Input entries are next-node indices; -1 means null and node 0 is the head.
export fn linked_list_has_cycle(next: [*]const i64, length: usize) i64 {
    if (!validSuccessors(next, length)) return -1;
    if (length == 0) return 0;
    var slow: i64 = 0;
    var fast: i64 = 0;
    while (fast >= 0) {
        const first = successor(next, fast);
        if (first < 0) break;
        slow = successor(next, slow);
        fast = successor(next, first);
        if (slow == fast) return 1;
    }
    return 0;
}
