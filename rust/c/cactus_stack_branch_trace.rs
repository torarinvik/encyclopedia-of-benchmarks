use core::slice;

const MAX_OPS: usize = 48;
const HANDLES: usize = 8;

#[derive(Clone, Copy)]
struct Node {
    value: i64,
    next: i32,
    child: i32,
    kind: u8,
    live: u8,
}

const EMPTY_NODE: Node = Node { value: 0, next: -1, child: -1, kind: 0, live: 0 };

fn normalize(mut head: i32, nodes: &[Node; MAX_OPS]) -> i32 {
    while head >= 0 {
        let node = nodes[head as usize];
        if node.kind != 1 || node.live != 0 { break; }
        head = node.next;
    }
    head
}

fn top_value(mut head: i32, nodes: &[Node; MAX_OPS]) -> Option<i64> {
    head = normalize(head, nodes);
    while head >= 0 && nodes[head as usize].kind == 1 {
        head = normalize(nodes[head as usize].next, nodes);
    }
    if head < 0 { None } else { Some(nodes[head as usize].value) }
}

unsafe fn run(input: &[i64], output: *mut u8, capacity: usize) -> i64 {
    if input.is_empty() || input.len() > 146 { return -1; }
    let q_value = input[0];
    if !(0..=MAX_OPS as i64).contains(&q_value) || input.len() != 1 + 3 * q_value as usize { return -1; }
    let q = q_value as usize;
    for i in 0..q {
        let op = input[1 + 3*i];
        let a = input[2 + 3*i];
        let b = input[3 + 3*i];
        let valid = match op {
            0 => (0..HANDLES as i64).contains(&a) && (-1000..=1000).contains(&b),
            1..=3 => (0..HANDLES as i64).contains(&a) && b == 0,
            4 => (0..HANDLES as i64).contains(&a) && (0..HANDLES as i64).contains(&b),
            _ => false,
        };
        if !valid { return -1; }
    }

    let mut nodes = [EMPTY_NODE; MAX_OPS];
    let mut heads = [-1i32; HANDLES];
    let mut branch_child = [-1i32; HANDLES];
    let mut attached_owner = [-1i32; HANDLES];
    let mut wrapper_for_child = [-1i32; HANDLES];
    let mut statuses = [0i64; MAX_OPS];
    let mut results = [0i64; MAX_OPS];
    let mut node_count = 0usize;

    for i in 0..q {
        let op = input[1 + 3*i] as i32;
        let a = input[2 + 3*i] as usize;
        let b = input[3 + 3*i];
        heads[a] = normalize(heads[a], &nodes);
        let head = heads[a];
        statuses[i] = 1;
        match op {
            0 => {
                nodes[node_count] = Node { value: b, next: head, child: -1, kind: 0, live: 0 };
                heads[a] = node_count as i32;
                node_count += 1;
            }
            1 => {
                if head < 0 || (nodes[head as usize].kind == 1 && nodes[head as usize].live != 0) {
                    statuses[i] = 0;
                } else {
                    results[i] = nodes[head as usize].value;
                    heads[a] = normalize(nodes[head as usize].next, &nodes);
                    if heads[a] < 0 && attached_owner[a] >= 0 {
                        let owner = attached_owner[a] as usize;
                        nodes[wrapper_for_child[a] as usize].live = 0;
                        branch_child[owner] = -1;
                        attached_owner[a] = -1;
                        wrapper_for_child[a] = -1;
                    }
                }
            }
            2 => match top_value(head, &nodes) {
                Some(value) => results[i] = value,
                None => statuses[i] = 0,
            },
            3 => results[i] = if head >= 0 && nodes[head as usize].kind == 1 && nodes[head as usize].live != 0 { 1 } else { 0 },
            _ => {
                let child = b as usize;
                heads[child] = normalize(heads[child], &nodes);
                if a == child || top_value(head, &nodes).is_none() || attached_owner[a] >= 0
                    || branch_child[a] >= 0 || attached_owner[child] >= 0 || branch_child[child] >= 0 { return -1; }
                if heads[child] < 0 { results[i] = 0; }
                else {
                    nodes[node_count] = Node { value: 0, next: head, child: child as i32, kind: 1, live: 1 };
                    let wrapper = node_count as i32;
                    node_count += 1;
                    heads[a] = wrapper;
                    branch_child[a] = child as i32;
                    attached_owner[child] = a as i32;
                    wrapper_for_child[child] = wrapper;
                    results[i] = 1;
                }
            }
        }
    }
    let required = 16 * q;
    if output.is_null() || capacity < required { return -2; }
    unsafe {
        for i in 0..q {
            for (field, value) in [statuses[i], results[i]].into_iter().enumerate() {
                let bits = value as u64;
                for byte in 0..8 { *output.add(16*i + 8*field + byte) = (bits >> (8*byte)) as u8; }
            }
        }
    }
    required as i64
}

#[no_mangle]
pub unsafe extern "C" fn cactus_stack_branch_trace(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length == 0 || length > 146 { return -1; }
    let values = unsafe { slice::from_raw_parts(input, length) };
    unsafe { run(values, output, capacity) }
}
