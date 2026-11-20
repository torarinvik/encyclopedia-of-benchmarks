const MAX_OPERATIONS: usize = 64;
const MAX_KEY_LENGTH: usize = 6;
const RECORD_WIDTH: usize = 9;
const MAX_INPUT_VALUES: usize = 577;
const MAX_PARSEABLE_INPUT_VALUES: usize = 578;
const MAX_NODES: usize = 384;

#[derive(Clone, Copy, Default)]
struct Node {
    character: i64,
    left: usize,
    middle: usize,
    right: usize,
    value: i64,
    present: bool,
}

fn bool_count(value: bool) -> usize {
    if value { 1 } else { 0 }
}

fn put_node(nodes: &mut [Node; MAX_NODES + 1], mut node_id: usize,
            key: &[i64], length: usize, depth: usize, value: i64,
            old_value: &mut i64, size: &mut usize, node_count: &mut usize) -> usize {
    if node_id == 0 {
        *node_count += 1;
        node_id = *node_count;
        nodes[node_id].character = key[depth];
    }
    if key[depth] < nodes[node_id].character {
        let child = put_node(nodes, nodes[node_id].left, key, length,
            depth, value, old_value, size, node_count);
        nodes[node_id].left = child;
    } else if key[depth] > nodes[node_id].character {
        let child = put_node(nodes, nodes[node_id].right, key, length,
            depth, value, old_value, size, node_count);
        nodes[node_id].right = child;
    } else if depth + 1 < length {
        let child = put_node(nodes, nodes[node_id].middle, key, length,
            depth + 1, value, old_value, size, node_count);
        nodes[node_id].middle = child;
    } else {
        *old_value = if nodes[node_id].present { nodes[node_id].value } else { 0 };
        if !nodes[node_id].present { *size += 1; }
        nodes[node_id].value = value;
        nodes[node_id].present = true;
    }
    node_id
}

fn find_node(nodes: &[Node; MAX_NODES + 1], mut node_id: usize,
             key: &[i64], length: usize) -> usize {
    let mut depth = 0;
    while node_id != 0 {
        if key[depth] < nodes[node_id].character {
            node_id = nodes[node_id].left;
        } else if key[depth] > nodes[node_id].character {
            node_id = nodes[node_id].right;
        } else if depth + 1 == length {
            return node_id;
        } else {
            node_id = nodes[node_id].middle;
            depth += 1;
        }
    }
    0
}

fn delete_node(nodes: &mut [Node; MAX_NODES + 1], node_id: usize,
               key: &[i64], length: usize, depth: usize,
               removed: &mut i64, size: &mut usize) -> usize {
    if node_id == 0 { return 0; }
    if key[depth] < nodes[node_id].character {
        let child = delete_node(nodes, nodes[node_id].left, key, length, depth,
                                removed, size);
        nodes[node_id].left = child;
    } else if key[depth] > nodes[node_id].character {
        let child = delete_node(nodes, nodes[node_id].right, key, length, depth,
                                removed, size);
        nodes[node_id].right = child;
    } else if depth + 1 < length {
        let child = delete_node(nodes, nodes[node_id].middle, key, length, depth + 1,
                                removed, size);
        nodes[node_id].middle = child;
    } else if nodes[node_id].present {
        *removed = nodes[node_id].value;
        nodes[node_id].value = 0;
        nodes[node_id].present = false;
        *size -= 1;
    }
    let node = nodes[node_id];
    if !node.present && node.left == 0 && node.middle == 0 && node.right == 0 {
        0
    } else {
        node_id
    }
}

fn count_nodes(nodes: &[Node; MAX_NODES + 1], node_id: usize) -> usize {
    if node_id == 0 { return 0; }
    bool_count(nodes[node_id].present)
        + count_nodes(nodes, nodes[node_id].left)
        + count_nodes(nodes, nodes[node_id].middle)
        + count_nodes(nodes, nodes[node_id].right)
}

fn count_matches(nodes: &[Node; MAX_NODES + 1], node_id: usize,
                 pattern: &[i64], length: usize, depth: usize) -> usize {
    if node_id == 0 { return 0; }
    let node = nodes[node_id];
    let token = pattern[depth];
    if token == 46 {
        let here = if depth + 1 == length { bool_count(node.present) }
                   else { count_matches(nodes, node.middle, pattern, length, depth + 1) };
        return count_matches(nodes, node.left, pattern, length, depth) + here
             + count_matches(nodes, node.right, pattern, length, depth);
    }
    if token < node.character {
        count_matches(nodes, node.left, pattern, length, depth)
    } else if token > node.character {
        count_matches(nodes, node.right, pattern, length, depth)
    } else if depth + 1 == length {
        bool_count(node.present)
    } else {
        count_matches(nodes, node.middle, pattern, length, depth + 1)
    }
}

fn valid_input(values: &[i64]) -> Option<usize> {
    if values.is_empty() || values.len() > MAX_PARSEABLE_INPUT_VALUES { return None; }
    if values[0] < 0 || values[0] > MAX_OPERATIONS as i64 { return None; }
    let operation_count = values[0] as usize;
    if values.len() != 1 + operation_count * RECORD_WIDTH { return None; }
    for operation in 0..operation_count {
        let base = 1 + operation * RECORD_WIDTH;
        let opcode = values[base];
        let key_length = values[base + 1];
        if !(0..=6).contains(&opcode) || !(0..=MAX_KEY_LENGTH as i64).contains(&key_length) {
            return None;
        }
        if (opcode <= 2 && key_length == 0) || (opcode == 6 && key_length != 0) {
            return None;
        }
        for index in 0..MAX_KEY_LENGTH {
            let character = values[base + 2 + index];
            if index < key_length as usize {
                if !((97..=122).contains(&character) ||
                    (opcode == 5 && character == 46)) { return None; }
            } else if character != 0 { return None; }
        }
        let value = values[base + RECORD_WIDTH - 1];
        if opcode == 0 {
            if !(1..=65535).contains(&value) { return None; }
        } else if value != 0 { return None; }
    }
    Some(operation_count)
}

#[no_mangle]
pub unsafe extern "C" fn ternary_search_trie(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_PARSEABLE_INPUT_VALUES { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let operation_count = match valid_input(values) {
        Some(count) => count,
        None => return -1,
    };
    let mut nodes = [Node::default(); MAX_NODES + 1];
    let mut node_count = 0;
    let mut root = 0;
    let mut size = 0;
    let mut total = 0_i64;
    for operation in 0..operation_count {
        let base = 1 + operation * RECORD_WIDTH;
        let opcode = values[base];
        let key_length = values[base + 1] as usize;
        let key = &values[base + 2..base + 2 + MAX_KEY_LENGTH];
        let value = values[base + RECORD_WIDTH - 1];
        let mut observed = 0_i64;
        if opcode == 0 {
            root = put_node(&mut nodes, root, key, key_length, 0, value,
                            &mut observed, &mut size, &mut node_count);
        } else if opcode == 1 {
            let found = find_node(&nodes, root, key, key_length);
            if found != 0 && nodes[found].present { observed = nodes[found].value; }
        } else if opcode == 2 {
            root = delete_node(&mut nodes, root, key, key_length, 0,
                               &mut observed, &mut size);
        } else if opcode == 3 {
            let mut node_id = root;
            let mut depth = 0;
            while node_id != 0 && depth < key_length {
                let node = nodes[node_id];
                if key[depth] < node.character { node_id = node.left; }
                else if key[depth] > node.character { node_id = node.right; }
                else {
                    depth += 1;
                    if node.present { observed = depth as i64; }
                    node_id = node.middle;
                }
            }
        } else if opcode == 4 {
            if key_length == 0 { observed = size as i64; }
            else {
                let found = find_node(&nodes, root, key, key_length);
                if found != 0 {
                    observed = (bool_count(nodes[found].present)
                        + count_nodes(&nodes, nodes[found].middle)) as i64;
                }
            }
        } else if opcode == 5 && key_length != 0 {
            observed = count_matches(&nodes, root, key, key_length, 0) as i64;
        } else if opcode == 6 {
            observed = size as i64;
        }
        total += (operation as i64 + 1) * observed;
    }
    total
}
