#[derive(Clone, Copy)]
struct Node { key: i64, left: i32, right: i32, size: i32 }

impl Node {
    const EMPTY: Self = Self { key: 0, left: -1, right: -1, size: 0 };
}

struct State { nodes: [Node; 64], used: usize, random_state: u32 }

fn size_of(state: &State, root: i32) -> i32 {
    if root < 0 { 0 } else { state.nodes[root as usize].size }
}

fn refresh(state: &mut State, root: i32) {
    let index = root as usize;
    state.nodes[index].size = 1 + size_of(state, state.nodes[index].left) + size_of(state, state.nodes[index].right);
}

fn randbelow(state: &mut State, bound: u32) -> u32 {
    let threshold = (1u64 << 32) % u64::from(bound);
    loop {
        state.random_state = state.random_state.wrapping_mul(1_664_525).wrapping_add(1_013_904_223);
        let raw = state.random_state;
        if u64::from(raw) >= threshold { return raw % bound; }
    }
}

fn make_node(state: &mut State, key: i64, left: i32, right: i32) -> i32 {
    let id = state.used as i32;
    state.used += 1;
    state.nodes[id as usize] = Node { key, left, right, size: 1 };
    refresh(state, id);
    id
}

fn split(state: &mut State, root: i32, pivot: i64) -> (i32, i32) {
    if root < 0 { return (-1, -1); }
    let index = root as usize;
    let key = state.nodes[index].key;
    if key < pivot {
        let right = state.nodes[index].right;
        let (low, high) = split(state, right, pivot);
        state.nodes[index].right = low;
        refresh(state, root);
        (root, high)
    } else {
        let left = state.nodes[index].left;
        let (low, high) = split(state, left, pivot);
        state.nodes[index].left = high;
        refresh(state, root);
        (low, root)
    }
}

fn join(state: &mut State, left: i32, right: i32) -> i32 {
    if left < 0 { return right; }
    if right < 0 { return left; }
    let left_size = size_of(state, left) as u32;
    let total = left_size + size_of(state, right) as u32;
    if randbelow(state, total) < left_size {
        let child = state.nodes[left as usize].right;
        let joined = join(state, child, right);
        state.nodes[left as usize].right = joined;
        refresh(state, left);
        left
    } else {
        let child = state.nodes[right as usize].left;
        let joined = join(state, left, child);
        state.nodes[right as usize].left = joined;
        refresh(state, right);
        right
    }
}

fn contains(state: &State, mut root: i32, key: i64) -> bool {
    while root >= 0 {
        let node = state.nodes[root as usize];
        if key == node.key { return true; }
        root = if key < node.key { node.left } else { node.right };
    }
    false
}

fn insert_absent(state: &mut State, root: i32, key: i64) -> i32 {
    if root < 0 { return make_node(state, key, -1, -1); }
    if randbelow(state, (size_of(state, root) + 1) as u32) == 0 {
        let (left, right) = split(state, root, key);
        return make_node(state, key, left, right);
    }
    let index = root as usize;
    let node_key = state.nodes[index].key;
    if key < node_key {
        let child = state.nodes[index].left;
        let inserted = insert_absent(state, child, key);
        state.nodes[index].left = inserted;
    } else {
        let child = state.nodes[index].right;
        let inserted = insert_absent(state, child, key);
        state.nodes[index].right = inserted;
    }
    refresh(state, root);
    root
}

fn erase_key(state: &mut State, root: i32, key: i64) -> i32 {
    if root < 0 { return -1; }
    let index = root as usize;
    let node_key = state.nodes[index].key;
    if key == node_key {
        let left = state.nodes[index].left;
        let right = state.nodes[index].right;
        return join(state, left, right);
    }
    if key < node_key {
        let child = state.nodes[index].left;
        let erased = erase_key(state, child, key);
        state.nodes[index].left = erased;
    } else {
        let child = state.nodes[index].right;
        let erased = erase_key(state, child, key);
        state.nodes[index].right = erased;
    }
    refresh(state, root);
    root
}

fn kth(state: &State, mut root: i32, mut rank: i32) -> i64 {
    if rank > size_of(state, root) { return -1; }
    while root >= 0 {
        let node = state.nodes[root as usize];
        let left_size = size_of(state, node.left);
        if rank == left_size + 1 { return node.key; }
        if rank <= left_size { root = node.left; }
        else { rank -= left_size + 1; root = node.right; }
    }
    -1
}

fn minimum(state: &State, mut root: i32) -> i64 {
    if root < 0 { return -1; }
    while state.nodes[root as usize].left >= 0 { root = state.nodes[root as usize].left; }
    state.nodes[root as usize].key
}

fn maximum(state: &State, mut root: i32) -> i64 {
    if root < 0 { return -1; }
    while state.nodes[root as usize].right >= 0 { root = state.nodes[root as usize].right; }
    state.nodes[root as usize].key
}

fn valid_operation(v: &[i64], at: usize) -> bool {
    let (op, a, b, c) = (v[at], v[at + 1], v[at + 2], v[at + 3]);
    match op {
        0 | 1 => (0..=1).contains(&a) && (0..=1000).contains(&b) && c == 0,
        2 => (0..=1).contains(&a) && (1..=65).contains(&b) && c == 0,
        3 => (0..=1).contains(&a) && (0..=1).contains(&b) && a != b && (0..=1001).contains(&c),
        4 => (0..=1).contains(&a) && (0..=1).contains(&b) && a != b && c == 0,
        _ => false,
    }
}

#[no_mangle]
pub unsafe extern "C" fn randomized_binary_search_tree_order_statistics_split_join(
    input: *const i64, length: usize,
) -> i64 {
    if input.is_null() || !(3..=164).contains(&length) { return -1; }
    let v = unsafe { std::slice::from_raw_parts(input, length) };
    let (n0, q0, seed) = (v[0], v[1], v[2]);
    if !(0..=32).contains(&n0) || !(0..=32).contains(&q0) || !(0..=4_294_967_295).contains(&seed) { return -1; }
    let (n, q) = (n0 as usize, q0 as usize);
    if length != 3 + n + 4 * q { return -1; }
    for i in 0..n {
        if !(0..=1000).contains(&v[3 + i]) || (i > 0 && v[2 + i] >= v[3 + i]) { return -1; }
    }
    let start = 3 + n;
    for operation in 0..q { if !valid_operation(v, start + 4 * operation) { return -1; } }

    let mut state = State { nodes: [Node::EMPTY; 64], used: 0, random_state: seed as u32 };
    let mut roots = [-1i32; 2];
    for i in 0..n { roots[0] = insert_absent(&mut state, roots[0], v[3 + i]); }
    let mut checksum = 0i64;
    let mut query_number = 0i64;
    for operation in 0..q {
        let at = start + 4 * operation;
        let (op, tree, arg, extra) = (v[at], v[at + 1] as usize, v[at + 2], v[at + 3]);
        if op == 0 {
            if !contains(&state, roots[tree], arg) { roots[tree] = insert_absent(&mut state, roots[tree], arg); }
        } else if op == 1 { roots[tree] = erase_key(&mut state, roots[tree], arg); }
        else if op == 2 { query_number += 1; checksum += query_number * (kth(&state, roots[tree], arg as i32) + 1); }
        else if op == 3 {
            let destination = arg as usize;
            if roots[destination] >= 0 { return -1; }
            let (low, high) = split(&mut state, roots[tree], extra);
            roots[tree] = low; roots[destination] = high;
        } else {
            let right = arg as usize;
            let left_max = maximum(&state, roots[tree]);
            let right_min = minimum(&state, roots[right]);
            if left_max >= 0 && right_min >= 0 && left_max >= right_min { return -1; }
            roots[tree] = join(&mut state, roots[tree], roots[right]); roots[right] = -1;
        }
    }
    checksum
}
