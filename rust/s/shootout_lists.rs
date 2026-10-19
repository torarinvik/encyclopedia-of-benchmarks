const LIST_SIZE: usize = 100;
const MIN_RUNS: i64 = 0;
const MAX_RUNS: i64 = 10_000;
const NODE_COUNT: usize = 203;

#[derive(Clone, Copy, Default)]
struct ListNode { value: i32, next: usize, prev: usize }

fn init_sequence(nodes: &mut [ListNode; NODE_COUNT], head: usize, base: usize) {
    nodes[head].value = LIST_SIZE as i32;
    nodes[head].next = base;
    nodes[head].prev = base + LIST_SIZE - 1;
    for offset in 0..LIST_SIZE {
        let item = base + offset;
        nodes[item].value = (offset + 1) as i32;
        nodes[item].prev = if offset == 0 { head } else { item - 1 };
        nodes[item].next = if offset + 1 == LIST_SIZE { head } else { item + 1 };
    }
}

fn list_length(nodes: &[ListNode; NODE_COUNT], head: usize) -> i32 { nodes[head].value }

fn pop_head(nodes: &mut [ListNode; NODE_COUNT], head: usize) -> Option<usize> {
    if list_length(nodes, head) == 0 { return None; }
    let item = nodes[head].next;
    let next = nodes[item].next;
    nodes[head].next = next;
    nodes[next].prev = head;
    nodes[head].value -= 1;
    Some(item)
}

fn pop_tail(nodes: &mut [ListNode; NODE_COUNT], head: usize) -> Option<usize> {
    if list_length(nodes, head) == 0 { return None; }
    let item = nodes[head].prev;
    let prev = nodes[item].prev;
    nodes[head].prev = prev;
    nodes[prev].next = head;
    nodes[head].value -= 1;
    Some(item)
}

fn push_tail(nodes: &mut [ListNode; NODE_COUNT], head: usize, item: usize) {
    let tail = nodes[head].prev;
    nodes[tail].next = item;
    nodes[item].next = head;
    nodes[head].prev = item;
    nodes[item].prev = tail;
    nodes[head].value += 1;
}

fn reverse_list(nodes: &mut [ListNode; NODE_COUNT], head: usize) {
    let mut current = head;
    loop {
        let old_next = nodes[current].next;
        nodes[current].next = nodes[current].prev;
        nodes[current].prev = old_next;
        current = old_next;
        if current == head { break; }
    }
}

fn lists_equal(nodes: &[ListNode; NODE_COUNT], left: usize, right: usize) -> bool {
    if list_length(nodes, left) != list_length(nodes, right) { return false; }
    let (mut a, mut b) = (nodes[left].next, nodes[right].next);
    while a != left && b != right {
        if nodes[a].value != nodes[b].value { return false; }
        a = nodes[a].next;
        b = nodes[b].next;
    }
    a == left && b == right
}

fn test_lists() -> bool {
    let mut nodes = [ListNode::default(); NODE_COUNT];
    const ORIGINAL: usize = 0;
    const COPIED: usize = 101;
    const STAGING: usize = 202;
    init_sequence(&mut nodes, ORIGINAL, 1);
    init_sequence(&mut nodes, COPIED, 102);
    nodes[STAGING].value = 0;
    nodes[STAGING].next = STAGING;
    nodes[STAGING].prev = STAGING;
    if !lists_equal(&nodes, COPIED, ORIGINAL) { return false; }
    while list_length(&nodes, COPIED) > 0 {
        let Some(item) = pop_head(&mut nodes, COPIED) else { return false; };
        push_tail(&mut nodes, STAGING, item);
    }
    if list_length(&nodes, COPIED) != 0 { return false; }
    while list_length(&nodes, STAGING) > 0 {
        let Some(item) = pop_tail(&mut nodes, STAGING) else { return false; };
        push_tail(&mut nodes, COPIED, item);
    }
    if list_length(&nodes, STAGING) != 0 { return false; }
    reverse_list(&mut nodes, ORIGINAL);
    nodes[nodes[ORIGINAL].next].value == LIST_SIZE as i32
        && nodes[nodes[ORIGINAL].prev].value == 1
        && nodes[nodes[COPIED].next].value == LIST_SIZE as i32
        && nodes[nodes[COPIED].prev].value == 1
        && list_length(&nodes, ORIGINAL) == LIST_SIZE as i32
        && lists_equal(&nodes, ORIGINAL, COPIED)
}

#[no_mangle]
pub unsafe extern "C" fn shootout_lists(runs: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(MIN_RUNS..=MAX_RUNS).contains(&runs) { return -1; }
    if output.is_null() { return -2; }
    let staged: &[u8] = if runs == 0 { b"0\n" } else { b"100\n" };
    if output_capacity < staged.len() { return -2; }
    for _ in 0..runs {
        if !test_lists() { return -1; }
    }
    for (index, byte) in staged.iter().enumerate() { *output.add(index) = *byte; }
    staged.len() as i64
}
