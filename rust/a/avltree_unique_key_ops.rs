const MAX_NODES: usize = 128;
const MAX_OPS: usize = 128;

#[derive(Clone, Copy)]
struct Node { key: i64, left: i32, right: i32, height: i32 }

fn height(nodes: &[Node; MAX_NODES], index: i32) -> i32 {
    if index < 0 { 0 } else { nodes[index as usize].height }
}
fn update(nodes: &mut [Node; MAX_NODES], index: usize) {
    nodes[index].height = 1 + height(nodes, nodes[index].left).max(height(nodes, nodes[index].right));
}
fn rotate_right(nodes: &mut [Node; MAX_NODES], root: usize) -> usize {
    let pivot = nodes[root].left as usize;
    let middle = nodes[pivot].right;
    nodes[pivot].right = root as i32;
    nodes[root].left = middle;
    update(nodes, root);
    update(nodes, pivot);
    pivot
}
fn rotate_left(nodes: &mut [Node; MAX_NODES], root: usize) -> usize {
    let pivot = nodes[root].right as usize;
    let middle = nodes[pivot].left;
    nodes[pivot].left = root as i32;
    nodes[root].right = middle;
    update(nodes, root);
    update(nodes, pivot);
    pivot
}
fn rebalance(nodes: &mut [Node; MAX_NODES], root: usize) -> usize {
    update(nodes, root);
    let balance = height(nodes, nodes[root].left) - height(nodes, nodes[root].right);
    if balance > 1 {
        let left = nodes[root].left as usize;
        if height(nodes, nodes[left].right) > height(nodes, nodes[left].left) {
            nodes[root].left = rotate_left(nodes, left) as i32;
        }
        return rotate_right(nodes, root);
    }
    if balance < -1 {
        let right = nodes[root].right as usize;
        if height(nodes, nodes[right].left) > height(nodes, nodes[right].right) {
            nodes[root].right = rotate_right(nodes, right) as i32;
        }
        return rotate_left(nodes, root);
    }
    root
}
fn insert(nodes: &mut [Node; MAX_NODES], root: i32, key: i64, next: &mut usize) -> usize {
    if root < 0 {
        let index = *next;
        *next += 1;
        nodes[index] = Node { key, left: -1, right: -1, height: 1 };
        return index;
    }
    let index = root as usize;
    if key < nodes[index].key {
        nodes[index].left = insert(nodes, nodes[index].left, key, next) as i32;
    } else {
        nodes[index].right = insert(nodes, nodes[index].right, key, next) as i32;
    }
    rebalance(nodes, index)
}
fn contains(nodes: &[Node; MAX_NODES], mut root: i32, key: i64) -> bool {
    while root >= 0 {
        let index = root as usize;
        if nodes[index].key == key { return true; }
        root = if key < nodes[index].key { nodes[index].left } else { nodes[index].right };
    }
    false
}
fn maximum_node(nodes: &[Node; MAX_NODES], mut root: i32) -> usize {
    while nodes[root as usize].right >= 0 { root = nodes[root as usize].right; }
    root as usize
}
fn delete(nodes: &mut [Node; MAX_NODES], root: usize, key: i64) -> i32 {
    if key < nodes[root].key {
        let child = delete(nodes, nodes[root].left as usize, key);
        nodes[root].left = child;
    } else if key > nodes[root].key {
        let child = delete(nodes, nodes[root].right as usize, key);
        nodes[root].right = child;
    } else {
        if nodes[root].left < 0 { return nodes[root].right; }
        if nodes[root].right < 0 { return nodes[root].left; }
        let predecessor = maximum_node(nodes, nodes[root].left);
        let replacement = nodes[predecessor].key;
        nodes[root].key = replacement;
        nodes[root].left = delete(nodes, nodes[root].left as usize, replacement);
    }
    rebalance(nodes, root) as i32
}
unsafe fn put_i64(output: *mut u8, offset: usize, value: i64) {
    for (byte, value_byte) in value.to_le_bytes().iter().enumerate() {
        *output.add(offset + byte) = *value_byte;
    }
}

#[no_mangle]
pub unsafe extern "C" fn avltree_unique_key_ops(input: *const i64, length: usize,
                                                  output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let operation_count = values[0];
    if !(0..=MAX_OPS as i64).contains(&operation_count) || length != 1 + 2 * operation_count as usize { return -1; }
    let operation_count = operation_count as usize;
    let mut active = [0i64; MAX_NODES];
    let mut active_count = 0usize;
    let mut search_count = 0usize;
    for index in 0..operation_count {
        let (operation, key) = (values[1 + 2 * index], values[2 + 2 * index]);
        if !(0..=2).contains(&operation) || !(-1_000_000..=1_000_000).contains(&key) { return -1; }
        let found = active[..active_count].iter().position(|&value| value == key);
        if operation == 0 {
            if found.is_some() || active_count >= MAX_NODES { return -1; }
            active[active_count] = key;
            active_count += 1;
        } else if operation == 1 {
            search_count += 1;
        } else {
            let Some(position) = found else { return -1; };
            active.copy_within(position + 1..active_count, position);
            active_count -= 1;
        }
    }

    let mut nodes = [Node { key: 0, left: -1, right: -1, height: 0 }; MAX_NODES];
    let (mut root, mut next) = (-1i32, 0usize);
    let mut results = [0i64; MAX_OPS];
    let mut result_count = 0usize;
    for index in 0..operation_count {
        let (operation, key) = (values[1 + 2 * index], values[2 + 2 * index]);
        if operation == 0 {
            root = insert(&mut nodes, root, key, &mut next) as i32;
        } else if operation == 1 {
            results[result_count] = contains(&nodes, root, key) as i64;
            result_count += 1;
        } else {
            root = delete(&mut nodes, root as usize, key);
        }
    }
    let bytes = (2 + active_count + search_count) * 8;
    if output.is_null() || capacity < bytes { return -2; }
    unsafe { put_i64(output, 0, active_count as i64); }
    let mut stack = [0usize; MAX_NODES];
    let (mut top, mut current, mut out) = (0usize, root, 1usize);
    while current >= 0 || top > 0 {
        while current >= 0 { stack[top] = current as usize; top += 1; current = nodes[current as usize].left; }
        top -= 1;
        let index = stack[top];
        unsafe { put_i64(output, out * 8, nodes[index].key); }
        out += 1;
        current = nodes[index].right;
    }
    unsafe { put_i64(output, out * 8, search_count as i64); }
    out += 1;
    for result in results.iter().take(search_count) {
        unsafe { put_i64(output, out * 8, *result); }
        out += 1;
    }
    bytes as i64
}
