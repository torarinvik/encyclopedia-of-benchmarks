module linked_list_cycle_entry;

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

// Returns the cycle-entry node index, -1 when acyclic, and -2 for malformed input.
fn long linked_list_cycle_entry(long* next, usz length) @export("linked_list_cycle_entry") {
    if (!valid_successors(next, length)) return -2;
    if (length == 0) return -1;
    long slow = 0;
    long fast = 0;
    bool meeting = false;
    while (fast >= 0) {
        long first = successor(next, fast);
        if (first < 0) break;
        slow = successor(next, slow);
        fast = successor(next, first);
        if (slow == fast) { meeting = true; break; }
    }
    if (!meeting) return -1;
    long entry = 0;
    while (entry != slow) {
        entry = successor(next, entry);
        slow = successor(next, slow);
    }
    return entry;
}
