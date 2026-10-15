/// Floyd cycle-entry search over a portable successor-index representation.
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

/// Returns the cycle-entry node index, -1 when acyclic, and -2 for malformed input.
export fn linked_list_cycle_entry(next: [*]const i64, length: usize) i64 {
    if (!validSuccessors(next, length)) return -2;
    if (length == 0) return -1;
    var slow: i64 = 0;
    var fast: i64 = 0;
    var meeting = false;
    while (fast >= 0) {
        const first = successor(next, fast);
        if (first < 0) break;
        slow = successor(next, slow);
        fast = successor(next, first);
        if (slow == fast) { meeting = true; break; }
    }
    if (!meeting) return -1;
    var entry: i64 = 0;
    while (entry != slow) {
        entry = successor(next, entry);
        slow = successor(next, slow);
    }
    return entry;
}
