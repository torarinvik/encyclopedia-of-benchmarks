module linked_list_has_cycle;

const usz MAX_NODES = 100000;

fn bool valid_successors(long* next, usz length) {
    if (length > MAX_NODES || (length != 0 && next == null)) return false;
    for (usz i = 0; i < length; i++) {
        if (next[i] < -1 || next[i] >= (long)length) return false;
    }
    return true;
}

fn long successor(long* next, long node) {
    return node < 0 ? -1 : next[(usz)node];
}

// Successor indices use -1 for null and node 0 as the head. Returns -1 on malformed input.
fn long linked_list_has_cycle(long* next, usz length) @export("linked_list_has_cycle") {
    if (!valid_successors(next, length)) return -1;
    if (length == 0) return 0;
    long slow = 0;
    long fast = 0;
    while (fast >= 0) {
        long first = successor(next, fast);
        if (first < 0) break;
        slow = successor(next, slow);
        fast = successor(next, first);
        if (slow == fast) return 1;
    }
    return 0;
}
