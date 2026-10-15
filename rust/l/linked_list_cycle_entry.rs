/// Floyd cycle-entry search over a portable successor-index representation.
const MAX_NODES: usize = 100_000;

fn valid_successors(next: *const i64, length: usize) -> bool {
    if length > MAX_NODES || (length != 0 && next.is_null()) { return false; }
    for index in 0..length {
        let value = unsafe { *next.add(index) };
        if value < -1 || value >= length as i64 { return false; }
    }
    true
}

fn successor(next: *const i64, node: i64) -> i64 {
    if node < 0 { -1 } else { unsafe { *next.add(node as usize) } }
}

/// Returns the cycle-entry node index, -1 when acyclic, and -2 for malformed input.
#[no_mangle]
pub extern "C" fn linked_list_cycle_entry(next: *const i64, length: usize) -> i64 {
    if !valid_successors(next, length) { return -2; }
    if length == 0 { return -1; }
    let (mut slow, mut fast) = (0i64, 0i64);
    let mut meeting = false;
    while fast >= 0 {
        let first = successor(next, fast);
        if first < 0 { break; }
        slow = successor(next, slow);
        fast = successor(next, first);
        if slow == fast { meeting = true; break; }
    }
    if !meeting { return -1; }
    let mut entry = 0i64;
    while entry != slow {
        entry = successor(next, entry);
        slow = successor(next, slow);
    }
    entry
}
