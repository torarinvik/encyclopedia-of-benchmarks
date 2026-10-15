/// Floyd cycle detection over a portable successor-index representation.
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

/// Input entries are next-node indices; -1 means null and node 0 is the head.
#[no_mangle]
pub extern "C" fn linked_list_has_cycle(next: *const i64, length: usize) -> i64 {
    if !valid_successors(next, length) { return -1; }
    if length == 0 { return 0; }
    let (mut slow, mut fast) = (0i64, 0i64);
    while fast >= 0 {
        let first = successor(next, fast);
        if first < 0 { break; }
        slow = successor(next, slow);
        fast = successor(next, first);
        if slow == fast { return 1; }
    }
    0
}
