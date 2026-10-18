const MAX_OPS: usize = 64;
const MAX_KEYS: usize = 32;
const MAX_INPUT: usize = 130;
const MAX_OUTPUT: usize = 784;

#[derive(Clone, Copy, Default)]
struct Node { key: i32, left: i32, right: i32 }

fn write_word(output: &mut [u8; MAX_OUTPUT], offset: &mut usize, word: i64) {
    output[*offset..*offset + 8].copy_from_slice(&word.to_le_bytes());
    *offset += 8;
}

fn rotate_right(nodes: &mut [Node; MAX_OPS], root: i32) -> i32 {
    let child = nodes[root as usize].left; nodes[root as usize].left = nodes[child as usize].right; nodes[child as usize].right = root; child
}
fn rotate_left(nodes: &mut [Node; MAX_OPS], root: i32) -> i32 {
    let child = nodes[root as usize].right; nodes[root as usize].right = nodes[child as usize].left; nodes[child as usize].left = root; child
}
fn splay(nodes: &mut [Node; MAX_OPS], root: i32, key: i32) -> i32 {
    if root < 0 || nodes[root as usize].key == key { return root; }
    if key < nodes[root as usize].key {
        let left = nodes[root as usize].left; if left < 0 { return root; }
        if key < nodes[left as usize].key {
            let grandchild = nodes[left as usize].left;
            let child = splay(nodes, grandchild, key);
            nodes[left as usize].left = child;
            let rotated = rotate_right(nodes, root);
            if nodes[rotated as usize].left < 0 { return rotated; }
            return rotate_right(nodes, rotated);
        } else if key > nodes[left as usize].key {
            let grandchild = nodes[left as usize].right;
            let child = splay(nodes, grandchild, key);
            nodes[left as usize].right = child;
            if child >= 0 { let new_left = rotate_left(nodes, left); nodes[root as usize].left = new_left; }
        }
        if nodes[root as usize].left < 0 { root } else { rotate_right(nodes, root) }
    } else {
        let right = nodes[root as usize].right; if right < 0 { return root; }
        if key > nodes[right as usize].key {
            let grandchild = nodes[right as usize].right;
            let child = splay(nodes, grandchild, key);
            nodes[right as usize].right = child;
            let rotated = rotate_left(nodes, root);
            if nodes[rotated as usize].right < 0 { return rotated; }
            return rotate_left(nodes, rotated);
        } else if key < nodes[right as usize].key {
            let grandchild = nodes[right as usize].left;
            let child = splay(nodes, grandchild, key);
            nodes[right as usize].left = child;
            if child >= 0 { let new_right = rotate_right(nodes, right); nodes[root as usize].right = new_right; }
        }
        if nodes[root as usize].right < 0 { root } else { rotate_left(nodes, root) }
    }
}
fn inorder(nodes: &[Node; MAX_OPS], root: i32, out: &mut [i64; MAX_KEYS], count: &mut usize) {
    if root < 0 { return; }
    inorder(nodes, nodes[root as usize].left, out, count); out[*count] = nodes[root as usize].key as i64; *count += 1;
    inorder(nodes, nodes[root as usize].right, out, count);
}

#[no_mangle]
pub unsafe extern "C" fn splay_tree(input: *const i64, input_length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || input_length == 0 || input_length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if !(0..=MAX_OPS as i64).contains(&values[0]) { return -1; }
    let op_count = values[0] as usize;
    if input_length != 1 + 2 * op_count { return -1; }
    let mut ops = [0i64; MAX_OPS]; let mut keys = [0i64; MAX_OPS]; let mut tags = [0i64; MAX_OPS];
    let mut live = [0i64; MAX_KEYS]; let mut live_count = 0usize; let mut offset = 1usize;
    for i in 0..op_count {
        let op = values[offset]; let key = values[offset + 1]; offset += 2;
        if (op != 0 && op != 1 && op != 2) || key < i32::MIN as i64 || key > i32::MAX as i64 { return -1; }
        ops[i] = op; keys[i] = key;
        let found = live[..live_count].iter().position(|&value| value == key);
        if op == 0 {
            if found.is_some() || live_count == MAX_KEYS { return -1; }
            live[live_count] = key; live_count += 1;
        } else if op == 2 {
            if live_count == 0 { return -1; }
            if let Some(index) = found { live_count -= 1; live[index] = live[live_count]; }
        }
    }
    let mut nodes = [Node::default(); MAX_OPS]; let mut node_count = 0usize; let mut root = -1i32;
    for i in 0..op_count {
        let key = keys[i] as i32;
        if ops[i] == 0 {
            if root < 0 { nodes[node_count] = Node { key, left: -1, right: -1 }; root = node_count as i32; node_count += 1; }
            else {
                root = splay(&mut nodes, root, key); nodes[node_count] = Node { key, left: -1, right: -1 }; let fresh = node_count as i32; node_count += 1;
                if key < nodes[root as usize].key { nodes[fresh as usize].left = nodes[root as usize].left; nodes[fresh as usize].right = root; nodes[root as usize].left = -1; }
                else { nodes[fresh as usize].right = nodes[root as usize].right; nodes[fresh as usize].left = root; nodes[root as usize].right = -1; }
                root = fresh;
            }
            tags[i] = -2;
        } else if ops[i] == 1 { root = splay(&mut nodes, root, key); tags[i] = if root >= 0 && nodes[root as usize].key == key { 1 } else { 0 }; }
        else {
            root = splay(&mut nodes, root, key); tags[i] = -3;
            if nodes[root as usize].key == key { let left = nodes[root as usize].left; let right = nodes[root as usize].right; if left < 0 { root = right; } else { root = splay(&mut nodes, left, key); nodes[root as usize].right = right; } }
        }
    }
    let mut final_keys = [0i64; MAX_KEYS]; let mut final_count = 0usize; inorder(&nodes, root, &mut final_keys, &mut final_count);
    let mut staged = [0u8; MAX_OUTPUT]; let mut written = 0usize;
    write_word(&mut staged, &mut written, op_count as i64);
    for tag in tags.iter().take(op_count) { write_word(&mut staged, &mut written, *tag); }
    write_word(&mut staged, &mut written, final_count as i64);
    for key in final_keys.iter().take(final_count) { write_word(&mut staged, &mut written, *key); }
    if output.is_null() || capacity < written { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, written);
    written as i64
}
