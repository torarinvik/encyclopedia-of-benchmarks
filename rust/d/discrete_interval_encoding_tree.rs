const MAX_Q: usize = 32;
const ARENA: usize = 64;
const MIN_KEY: i64 = -15;
const MAX_KEY: i64 = 15;

#[derive(Clone, Copy, Default)]
struct Node {
    lo: i64,
    hi: i64,
    left: i32,
    right: i32,
}

fn new_node(nodes: &mut [Node; ARENA], used: &mut usize, lo: i64, hi: i64,
            left: i32, right: i32) -> i32 {
    let index = *used;
    nodes[index] = Node { lo, hi, left, right };
    *used += 1;
    index as i32
}

fn pop_max(nodes: &mut [Node; ARENA], root: i32) -> (i32, i64, i64) {
    let index = root as usize;
    if nodes[index].right < 0 {
        return (nodes[index].left, nodes[index].lo, nodes[index].hi);
    }
    let (right, lo, hi) = pop_max(nodes, nodes[index].right);
    nodes[index].right = right;
    (root, lo, hi)
}

fn pop_min(nodes: &mut [Node; ARENA], root: i32) -> (i32, i64, i64) {
    let index = root as usize;
    if nodes[index].left < 0 {
        return (nodes[index].right, nodes[index].lo, nodes[index].hi);
    }
    let (left, lo, hi) = pop_min(nodes, nodes[index].left);
    nodes[index].left = left;
    (root, lo, hi)
}

fn maximum_interval(nodes: &[Node; ARENA], mut root: i32) -> (i64, i64) {
    while nodes[root as usize].right >= 0 {
        root = nodes[root as usize].right;
    }
    let node = nodes[root as usize];
    (node.lo, node.hi)
}

fn minimum_interval(nodes: &[Node; ARENA], mut root: i32) -> (i64, i64) {
    while nodes[root as usize].left >= 0 {
        root = nodes[root as usize].left;
    }
    let node = nodes[root as usize];
    (node.lo, node.hi)
}

fn insert(nodes: &mut [Node; ARENA], used: &mut usize, root: i32, key: i64,
          interval_count: &mut i32, changed: &mut bool) -> i32 {
    if root < 0 {
        *interval_count += 1;
        *changed = true;
        return new_node(nodes, used, key, key, -1, -1);
    }
    let index = root as usize;
    let node = nodes[index];
    if key < node.lo {
        if key + 1 == node.lo {
            nodes[index].lo = key;
            *changed = true;
            if node.left >= 0 {
                let (_, pred_hi) = maximum_interval(nodes, node.left);
                if pred_hi + 1 == key {
                    let (left, pred_lo, _) = pop_max(nodes, node.left);
                    nodes[index].lo = pred_lo;
                    nodes[index].left = left;
                    *interval_count -= 1;
                }
            }
        } else {
            let left = insert(nodes, used, node.left, key, interval_count, changed);
            nodes[index].left = left;
        }
        return root;
    }
    if key > node.hi {
        if key == node.hi + 1 {
            nodes[index].hi = key;
            *changed = true;
            if node.right >= 0 {
                let (succ_lo, _) = minimum_interval(nodes, node.right);
                if key + 1 == succ_lo {
                    let (right, _, succ_hi) = pop_min(nodes, node.right);
                    nodes[index].hi = succ_hi;
                    nodes[index].right = right;
                    *interval_count -= 1;
                }
            }
        } else {
            let right = insert(nodes, used, node.right, key, interval_count, changed);
            nodes[index].right = right;
        }
        return root;
    }
    *changed = false;
    root
}

fn erase(nodes: &mut [Node; ARENA], used: &mut usize, root: i32, key: i64,
         interval_count: &mut i32, changed: &mut bool) -> i32 {
    if root < 0 {
        *changed = false;
        return root;
    }
    let index = root as usize;
    let node = nodes[index];
    if key < node.lo {
        let left = erase(nodes, used, node.left, key, interval_count, changed);
        nodes[index].left = left;
        return root;
    }
    if key > node.hi {
        let right = erase(nodes, used, node.right, key, interval_count, changed);
        nodes[index].right = right;
        return root;
    }
    *changed = true;
    if node.lo == node.hi {
        *interval_count -= 1;
        if node.left < 0 { return node.right; }
        if node.right < 0 { return node.left; }
        let (left, lo, hi) = pop_max(nodes, node.left);
        nodes[index].lo = lo;
        nodes[index].hi = hi;
        nodes[index].left = left;
        return root;
    }
    if key == node.lo {
        nodes[index].lo += 1;
        return root;
    }
    if key == node.hi {
        nodes[index].hi -= 1;
        return root;
    }
    let piece = new_node(nodes, used, key + 1, node.hi, -1, node.right);
    nodes[index].hi = key - 1;
    nodes[index].right = piece;
    *interval_count += 1;
    root
}

fn contains(nodes: &[Node; ARENA], mut root: i32, key: i64) -> bool {
    while root >= 0 {
        let node = nodes[root as usize];
        if key < node.lo { root = node.left; }
        else if key > node.hi { root = node.right; }
        else { return true; }
    }
    false
}

fn valid(input: &[i64]) -> Option<usize> {
    if input.is_empty() || input.len() > 2 + 2 * MAX_Q { return None; }
    if input[0] < 0 || input[0] > MAX_Q as i64 { return None; }
    let q = input[0] as usize;
    if input.len() != 1 + 2 * q { return None; }
    for op in 0..q {
        let opcode = input[1 + 2 * op];
        let key = input[2 + 2 * op];
        if !(0..=2).contains(&opcode) || !(MIN_KEY..=MAX_KEY).contains(&key) {
            return None;
        }
    }
    Some(q)
}

#[no_mangle]
pub unsafe extern "C" fn discrete_interval_encoding_tree(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length == 0 || length > 2 + 2 * MAX_Q { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let q = match valid(values) { Some(count) => count, None => return -1 };
    let required = q * 8;
    if (required > 0 && output.is_null()) || capacity < required { return -2; }

    let mut nodes = [Node::default(); ARENA];
    let mut used = 0usize;
    let mut root = -1i32;
    let mut cardinality = 0i64;
    let mut interval_count = 0i64;
    let mut staged = [0i64; MAX_Q];
    for i in 0..q {
        let opcode = values[1 + 2 * i];
        let key = values[2 + 2 * i];
        let mut changed = false;
        if opcode == 0 {
            root = insert(&mut nodes, &mut used, root, key, &mut interval_count, &mut changed);
            if changed { cardinality += 1; }
        } else if opcode == 1 {
            root = erase(&mut nodes, &mut used, root, key, &mut interval_count, &mut changed);
            if changed { cardinality -= 1; }
        }
        let present = if contains(&nodes, root, key) { 1 } else { 0 };
        staged[i] = 64 * cardinality + 2 * interval_count + present;
    }
    for i in 0..q {
        let bytes = staged[i].to_le_bytes();
        for (offset, byte) in bytes.iter().enumerate() {
            unsafe { output.add(i * 8 + offset).write(*byte); }
        }
    }
    required as i64
}
