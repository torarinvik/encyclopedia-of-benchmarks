const MAX_Q: usize = 128;
const TREE_BASE: usize = 128;
const TREE_HEIGHT: usize = 7;
const MAX_NODES: usize = 1 + MAX_Q * (TREE_HEIGHT + 1);
const MAX_PARSEABLE_INPUT: usize = 1 + 3 * MAX_Q + 1;
const MAX_VALUE: i64 = 1_000_000_000;

#[derive(Clone, Copy, Default)]
struct Node { left: usize, right: usize, value: i64 }

fn set_value(nodes: &mut [Node; MAX_NODES], used: &mut usize, root: usize,
             low: usize, high: usize, position: usize, value: i64) -> usize {
    let copy = *used;
    *used += 1;
    nodes[copy] = nodes[root];
    if high - low == 1 {
        nodes[copy].value = value;
        return copy;
    }
    let middle = low + (high - low) / 2;
    if position < middle {
        let child_root = nodes[root].left;
        let child = set_value(nodes, used, child_root, low, middle, position, value);
        nodes[copy].left = child;
    } else {
        let child_root = nodes[root].right;
        let child = set_value(nodes, used, child_root, middle, high, position, value);
        nodes[copy].right = child;
    }
    copy
}

fn get_value(nodes: &[Node; MAX_NODES], root: usize, low: usize,
             high: usize, position: usize) -> i64 {
    if high - low == 1 { return nodes[root].value; }
    let middle = low + (high - low) / 2;
    if position < middle {
        get_value(nodes, nodes[root].left, low, middle, position)
    } else {
        get_value(nodes, nodes[root].right, middle, high, position)
    }
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn persistent_queue(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT { return -1; }
    let q_value = *input;
    if q_value < 1 || q_value > MAX_Q as i64 { return -1; }
    let q = q_value as usize;
    let mut kind = [0i64; MAX_Q];
    let mut parent = [0i64; MAX_Q];
    let mut value = [0i64; MAX_Q];
    let mut version_head = [0usize; MAX_Q + 1];
    let mut version_tail = [0usize; MAX_Q + 1];
    let mut version_size = [0usize; MAX_Q + 1];
    let mut cursor = 1usize;
    let mut pop_count = 0usize;
    for operation in 0..q {
        if cursor + 2 > length { return -1; }
        kind[operation] = *input.add(cursor); cursor += 1;
        parent[operation] = *input.add(cursor); cursor += 1;
        if (kind[operation] != 0 && kind[operation] != 1) || parent[operation] < -1 ||
            parent[operation] >= operation as i64 { return -1; }
        let base = (parent[operation] + 1) as usize;
        if kind[operation] == 0 {
            if cursor >= length { return -1; }
            value[operation] = *input.add(cursor); cursor += 1;
            if value[operation] < 0 || value[operation] > MAX_VALUE ||
                version_tail[base] >= TREE_BASE { return -1; }
            version_head[operation + 1] = version_head[base];
            version_tail[operation + 1] = version_tail[base] + 1;
            version_size[operation + 1] = version_size[base] + 1;
        } else {
            if version_size[base] == 0 { return -1; }
            version_head[operation + 1] = version_head[base] + 1;
            version_tail[operation + 1] = version_tail[base];
            version_size[operation + 1] = version_size[base] - 1;
            pop_count += 1;
        }
    }
    if cursor != length { return -1; }
    let output_bytes = 8 * pop_count;
    if output_bytes > 0 && (output.is_null() || capacity < output_bytes) { return -2; }

    let mut nodes = [Node::default(); MAX_NODES];
    let mut roots = [0usize; MAX_Q + 1];
    let mut answers = [0i64; MAX_Q];
    let mut answer_count = 0usize;
    let mut used = 1usize;
    for operation in 0..q {
        let base = (parent[operation] + 1) as usize;
        let version = operation + 1;
        if kind[operation] == 0 {
            roots[version] = set_value(&mut nodes, &mut used, roots[base], 0, TREE_BASE,
                                       version_tail[base], value[operation]);
        } else {
            answers[answer_count] = get_value(&nodes, roots[base], 0, TREE_BASE,
                                              version_head[base]);
            answer_count += 1;
            roots[version] = roots[base];
        }
    }
    for index in 0..answer_count { store_i64_le(output, 8 * index, answers[index]); }
    output_bytes as i64
}
