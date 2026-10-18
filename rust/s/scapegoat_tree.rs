const MAX_OPERATIONS: usize = 64;
const MAX_LIVE_KEYS: usize = 32;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_OPERATIONS;
const MAX_PARSEABLE_INPUT_LENGTH: usize = MAX_INPUT_LENGTH + 1;
const MAX_OUTPUT_BYTES: usize = 8 * (2 + MAX_OPERATIONS + MAX_LIVE_KEYS);

#[derive(Clone, Copy)]
struct Node {
    key: i64,
    left: i32,
    right: i32,
    active: bool,
}

fn subtree_size(nodes: &[Node; MAX_LIVE_KEYS], root: i32) -> usize {
    if root < 0 { return 0; }
    let node = &nodes[root as usize];
    1 + subtree_size(nodes, node.left) + subtree_size(nodes, node.right)
}

fn alpha_height(nodes: &[Node; MAX_LIVE_KEYS], root: i32) -> usize {
    let mut size = subtree_size(nodes, root);
    let mut height = 0;
    while size > 1 {
        size >>= 1;
        height += 1;
    }
    height
}

fn flatten(nodes: &[Node; MAX_LIVE_KEYS], root: i32, order: &mut [i32; MAX_LIVE_KEYS], length: &mut usize) {
    if root < 0 { return; }
    let node = &nodes[root as usize];
    flatten(nodes, node.left, order, length);
    order[*length] = root;
    *length += 1;
    flatten(nodes, node.right, order, length);
}

fn rebuild(nodes: &mut [Node; MAX_LIVE_KEYS], order: &[i32; MAX_LIVE_KEYS], start: usize, end: usize) -> i32 {
    if start >= end { return -1; }
    let pivot = (start + end) / 2;
    let root = order[pivot];
    let left = rebuild(nodes, order, start, pivot);
    let right = rebuild(nodes, order, pivot + 1, end);
    nodes[root as usize].left = left;
    nodes[root as usize].right = right;
    root
}

fn find_key(nodes: &[Node; MAX_LIVE_KEYS], mut root: i32, key: i64) -> bool {
    while root >= 0 {
        let node = &nodes[root as usize];
        if node.key == key { return true; }
        root = if key < node.key { node.left } else { node.right };
    }
    false
}

fn allocate_node(nodes: &mut [Node; MAX_LIVE_KEYS], key: i64) -> i32 {
    for index in 0..MAX_LIVE_KEYS {
        if !nodes[index].active {
            nodes[index] = Node { key, left: -1, right: -1, active: true };
            return index as i32;
        }
    }
    -1
}

fn insert_key(nodes: &mut [Node; MAX_LIVE_KEYS], root: &mut i32, size: &mut usize, max_size: &mut usize, key: i64) -> bool {
    if *root < 0 {
        *root = allocate_node(nodes, key);
        if *root < 0 { return false; }
        *size += 1;
        *max_size = (*max_size).max(*size);
        return true;
    }

    let mut path = [0i32; MAX_LIVE_KEYS];
    let mut path_length = 0usize;
    let mut current = *root;
    loop {
        path[path_length] = current;
        path_length += 1;
        let node_key = nodes[current as usize].key;
        if key == node_key { return false; }
        let child = if key < node_key { nodes[current as usize].left } else { nodes[current as usize].right };
        if child < 0 {
            let new_node = allocate_node(nodes, key);
            if key < node_key { nodes[current as usize].left = new_node; }
            else { nodes[current as usize].right = new_node; }
            break;
        }
        current = child;
    }

    *size += 1;
    *max_size = (*max_size).max(*size);
    if path_length > alpha_height(nodes, *root) {
        let mut depth = 1usize;
        let mut scapegoat = -1i32;
        let mut parent = -1i32;
        while path_length > 0 {
            path_length -= 1;
            let candidate = path[path_length];
            if depth > alpha_height(nodes, candidate) {
                scapegoat = candidate;
                if path_length > 0 {
                    path_length -= 1;
                    parent = path[path_length];
                }
                break;
            }
            depth += 1;
        }
        let mut order = [-1i32; MAX_LIVE_KEYS];
        let mut order_length = 0usize;
        flatten(nodes, scapegoat, &mut order, &mut order_length);
        let rebuilt = rebuild(nodes, &order, 0, order_length);
        if parent < 0 { *root = rebuilt; }
        else if nodes[parent as usize].key < nodes[rebuilt as usize].key { nodes[parent as usize].right = rebuilt; }
        else { nodes[parent as usize].left = rebuilt; }
    }
    true
}

fn delete_key(nodes: &mut [Node; MAX_LIVE_KEYS], root: &mut i32, size: &mut usize, max_size: &mut usize, key: i64) -> bool {
    let mut parent = -1i32;
    let mut node = *root;
    while node >= 0 && nodes[node as usize].key != key {
        parent = node;
        node = if key < nodes[node as usize].key { nodes[node as usize].left } else { nodes[node as usize].right };
    }
    if node < 0 { return false; }

    let left = nodes[node as usize].left;
    let right = nodes[node as usize].right;
    if left >= 0 && right >= 0 {
        let mut predecessor_parent = node;
        let mut predecessor = left;
        while nodes[predecessor as usize].right >= 0 {
            predecessor_parent = predecessor;
            predecessor = nodes[predecessor as usize].right;
        }
        nodes[node as usize].key = nodes[predecessor as usize].key;
        let replacement = nodes[predecessor as usize].left;
        if predecessor_parent == node { nodes[node as usize].left = replacement; }
        else { nodes[predecessor_parent as usize].right = replacement; }
        nodes[predecessor as usize].active = false;
        nodes[predecessor as usize].left = -1;
        nodes[predecessor as usize].right = -1;
    } else {
        let replacement = if left >= 0 { left } else { right };
        if parent < 0 { *root = replacement; }
        else if nodes[parent as usize].left == node { nodes[parent as usize].left = replacement; }
        else { nodes[parent as usize].right = replacement; }
        nodes[node as usize].active = false;
        nodes[node as usize].left = -1;
        nodes[node as usize].right = -1;
    }

    *size -= 1;
    if *root >= 0 && 2 * *size < *max_size {
        let mut order = [-1i32; MAX_LIVE_KEYS];
        let mut order_length = 0usize;
        flatten(nodes, *root, &mut order, &mut order_length);
        *root = rebuild(nodes, &order, 0, order_length);
        *max_size = *size;
    }
    true
}

fn root_weight_balanced(nodes: &[Node; MAX_LIVE_KEYS], root: i32) -> bool {
    if root < 0 { return true; }
    let total = subtree_size(nodes, root);
    2 * subtree_size(nodes, nodes[root as usize].left) <= total &&
        2 * subtree_size(nodes, nodes[root as usize].right) <= total
}

fn put_i64_le(output: &mut [u8; MAX_OUTPUT_BYTES], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

unsafe fn run(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_OPERATIONS as i64 { return -1; }
    let operation_count = values[0] as usize;
    if length != 1 + 2 * operation_count { return -1; }

    let mut active_keys = [0i64; MAX_LIVE_KEYS];
    let mut active_count = 0usize;
    for operation in 0..operation_count {
        let offset = 1 + 2 * operation;
        let opcode = values[offset];
        let key = values[offset + 1];
        if key < i32::MIN as i64 || key > i32::MAX as i64 || !(0..=6).contains(&opcode) { return -1; }
        if opcode >= 3 && key != 0 { return -1; }
        if opcode == 0 {
            let mut present = false;
            for i in 0..active_count { if active_keys[i] == key { present = true; } }
            if !present {
                if active_count == MAX_LIVE_KEYS { return -1; }
                active_keys[active_count] = key;
                active_count += 1;
            }
        } else if opcode == 2 {
            for i in 0..active_count {
                if active_keys[i] == key {
                    for j in i..active_count - 1 { active_keys[j] = active_keys[j + 1]; }
                    active_count -= 1;
                    break;
                }
            }
        } else if opcode == 6 { active_count = 0; }
    }

    let mut nodes = [Node { key: 0, left: -1, right: -1, active: false }; MAX_LIVE_KEYS];
    let mut root = -1i32;
    let mut size = 0usize;
    let mut max_size = 0usize;
    let mut results = [0i64; MAX_OPERATIONS];
    for operation in 0..operation_count {
        let offset = 1 + 2 * operation;
        let opcode = values[offset];
        let key = values[offset + 1];
        results[operation] = match opcode {
            0 => if insert_key(&mut nodes, &mut root, &mut size, &mut max_size, key) { 1 } else { 0 },
            1 => if find_key(&nodes, root, key) { 1 } else { 0 },
            2 => if delete_key(&mut nodes, &mut root, &mut size, &mut max_size, key) { 1 } else { 0 },
            3 => size as i64,
            4 => max_size as i64,
            5 => if root_weight_balanced(&nodes, root) { 1 } else { 0 },
            _ => {
                for node in &mut nodes { node.active = false; node.left = -1; node.right = -1; }
                root = -1;
                size = 0;
                max_size = 0;
                -2
            }
        };
    }

    let output_bytes = (2 + operation_count + size) * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    put_i64_le(&mut staged, 0, operation_count as i64);
    for operation in 0..operation_count { put_i64_le(&mut staged, (1 + operation) * 8, results[operation]); }
    put_i64_le(&mut staged, (1 + operation_count) * 8, size as i64);
    let mut order = [-1i32; MAX_LIVE_KEYS];
    let mut order_length = 0usize;
    flatten(&nodes, root, &mut order, &mut order_length);
    for i in 0..order_length { put_i64_le(&mut staged, (2 + operation_count + i) * 8, nodes[order[i] as usize].key); }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_bytes);
    output_bytes as i64
}

#[no_mangle]
pub unsafe extern "C" fn scapegoat_tree(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    run(input, length, output, capacity)
}
