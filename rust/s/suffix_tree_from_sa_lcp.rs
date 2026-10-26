const MAX_TEXT: usize = 8;
const MAX_INPUT: usize = 10;
const MAX_SUFFIXES: usize = MAX_TEXT + 1;
const MAX_NODES: usize = 2 * MAX_SUFFIXES - 1;
const MAX_OUTPUT_WORDS: usize = 1 + 5 * MAX_NODES;

#[derive(Clone, Copy)]
struct TreeRecord {
    parent_rep: i64,
    parent_depth: i64,
    node_rep: i64,
    node_depth: i64,
    leaf_start: i64,
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

fn symbol_at(input: &[i64], text_length: usize, position: usize) -> i64 {
    if position == text_length { 0 } else { input[position + 1] }
}

fn suffix_less(input: &[i64], text_length: usize, mut left: usize, mut right: usize) -> bool {
    let total = text_length + 1;
    while left < total && right < total {
        let a = symbol_at(input, text_length, left);
        let b = symbol_at(input, text_length, right);
        if a != b { return a < b; }
        left += 1;
        right += 1;
    }
    left == total && right != total
}

fn record_less(left: TreeRecord, right: TreeRecord) -> bool {
    if left.node_depth != right.node_depth { return left.node_depth < right.node_depth; }
    if left.node_rep != right.node_rep { return left.node_rep < right.node_rep; }
    left.leaf_start < right.leaf_start
}

#[no_mangle]
pub unsafe extern "C" fn suffix_tree_from_sa_lcp(
    input_opt: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input_opt.is_null() || length < 1 || length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(input_opt, length);
    let n_raw = input[0];
    if n_raw < 0 || n_raw > MAX_TEXT as i64 || length != n_raw as usize + 1 { return -1; }
    let n = n_raw as usize;
    for i in 0..n { if input[i + 1] < 1 || input[i + 1] > 255 { return -1; } }

    let suffix_count = n + 1;
    let mut suffix_array = [0usize; MAX_SUFFIXES];
    let mut lcp = [0usize; MAX_SUFFIXES];
    for i in 0..suffix_count { suffix_array[i] = i; }
    for i in 1..suffix_count {
        let value = suffix_array[i];
        let mut j = i;
        while j > 0 && suffix_less(input, n, value, suffix_array[j - 1]) {
            suffix_array[j] = suffix_array[j - 1];
            j -= 1;
        }
        suffix_array[j] = value;
    }
    for rank in 1..suffix_count {
        let mut left = suffix_array[rank - 1];
        let mut right = suffix_array[rank];
        let mut common = 0;
        while left + common < suffix_count && right + common < suffix_count
            && symbol_at(input, n, left + common) == symbol_at(input, n, right + common) {
            common += 1;
        }
        lcp[rank] = common;
    }

    let mut parent = [0i32; MAX_NODES];
    let mut depth = [0i32; MAX_NODES];
    let mut representative = [0i32; MAX_NODES];
    let mut leaf = [-1i32; MAX_NODES];
    let mut last_child = [-1i32; MAX_NODES];
    let mut stack = [0usize; MAX_NODES];
    let mut node_count = 1usize;
    let mut stack_size = 1usize;
    parent[0] = -1; depth[0] = 0; representative[0] = -1; leaf[0] = -1;
    stack[0] = 0;
    for rank in 0..suffix_count {
        if rank > 0 {
            let common = lcp[rank] as i32;
            while stack_size > 1 && depth[stack[stack_size - 1]] > common { stack_size -= 1; }
            let top = stack[stack_size - 1];
            if depth[top] < common {
                let old_child = last_child[top];
                if old_child < 0 { return -1; }
                let old = old_child as usize;
                let internal = node_count;
                node_count += 1;
                parent[internal] = top as i32;
                depth[internal] = common;
                representative[internal] = representative[old];
                leaf[internal] = -1;
                last_child[internal] = old_child;
                parent[old] = internal as i32;
                last_child[top] = internal as i32;
                stack[stack_size] = internal;
                stack_size += 1;
            }
        }
        let owner = stack[stack_size - 1];
        let suffix_start = suffix_array[rank];
        let new_leaf = node_count;
        node_count += 1;
        parent[new_leaf] = owner as i32;
        depth[new_leaf] = (suffix_count - suffix_start) as i32;
        representative[new_leaf] = suffix_start as i32;
        leaf[new_leaf] = suffix_start as i32;
        last_child[new_leaf] = -1;
        last_child[owner] = new_leaf as i32;
    }

    let mut records = [TreeRecord { parent_rep: 0, parent_depth: 0, node_rep: 0, node_depth: 0, leaf_start: 0 }; MAX_NODES];
    for node in 0..node_count {
        if node == 0 {
            records[node] = TreeRecord { parent_rep: -1, parent_depth: -1, node_rep: -1, node_depth: 0, leaf_start: -1 };
        } else {
            let p = parent[node] as usize;
            records[node] = TreeRecord {
                parent_rep: representative[p] as i64,
                parent_depth: depth[p] as i64,
                node_rep: representative[node] as i64,
                node_depth: depth[node] as i64,
                leaf_start: leaf[node] as i64,
            };
        }
    }
    for i in 1..node_count {
        let value = records[i];
        let mut j = i;
        while j > 0 && record_less(value, records[j - 1]) {
            records[j] = records[j - 1];
            j -= 1;
        }
        records[j] = value;
    }
    let mut staged = [0i64; MAX_OUTPUT_WORDS];
    staged[0] = node_count as i64;
    let mut words = 1usize;
    for record in records.iter().take(node_count) {
        staged[words] = record.parent_rep; words += 1;
        staged[words] = record.parent_depth; words += 1;
        staged[words] = record.node_rep; words += 1;
        staged[words] = record.node_depth; words += 1;
        staged[words] = record.leaf_start; words += 1;
    }
    let bytes = words * 8;
    if output.is_null() || capacity < bytes { return -2; }
    for word in 0..words { store_i64_le(output, word * 8, staged[word]); }
    bytes as i64
}
