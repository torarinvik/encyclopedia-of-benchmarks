const MAX_OPERATIONS: usize = 64;
const MAX_NODES: usize = 1024;
const MAX_INPUT_WORDS: usize = 193;
const MAX_HEAP_SIZE: usize = 128;

#[derive(Clone, Copy, Default)]
struct HeapNode {
    key: i64,
    left: usize,
    right: usize,
    npl: i32,
    size: usize,
}

fn meld(nodes: &mut [HeapNode; MAX_NODES], used: &mut usize, first_root: usize, second_root: usize) -> Option<usize> {
    if first_root == 0 { return Some(second_root); }
    if second_root == 0 { return Some(first_root); }
    let (first, second) = if nodes[first_root].key > nodes[second_root].key {
        (second_root, first_root)
    } else {
        (first_root, second_root)
    };
    if *used >= MAX_NODES { return None; }
    let copy = *used;
    *used += 1;
    nodes[copy] = nodes[first];
    let prior_right = nodes[copy].right;
    let merged_right = meld(nodes, used, prior_right, second)?;
    nodes[copy].right = merged_right;
    if nodes[nodes[copy].left].npl < nodes[nodes[copy].right].npl {
        let node = &mut nodes[copy];
        std::mem::swap(&mut node.left, &mut node.right);
    }
    nodes[copy].npl = nodes[nodes[copy].right].npl + 1;
    nodes[copy].size = nodes[nodes[copy].left].size + nodes[nodes[copy].right].size + 1;
    Some(copy)
}

fn execute(input: &[i64]) -> Result<i64, ()> {
    if input.is_empty() || input.len() > MAX_INPUT_WORDS { return Err(()); }
    let operation_count64 = input[0];
    if operation_count64 < 0 || operation_count64 > MAX_OPERATIONS as i64 { return Err(()); }
    let operation_count = operation_count64 as usize;
    let mut nodes = [HeapNode::default(); MAX_NODES];
    nodes[0].npl = -1;
    let mut used = 1usize;
    let mut roots = [0usize; MAX_OPERATIONS + 1];
    let mut cursor = 1usize;
    let (mut rank_sum, mut rank_xor) = (0i64, 0i64);

    for operation in 0..operation_count {
        if cursor >= input.len() { return Err(()); }
        let kind = input[cursor];
        cursor += 1;
        if kind == 0 {
            if cursor + 2 > input.len() { return Err(()); }
            let (base64, key) = (input[cursor], input[cursor + 1]);
            cursor += 2;
            if base64 < 0 || base64 > operation as i64 || !(-10_000..=10_000).contains(&key) { return Err(()); }
            let base = base64 as usize;
            if nodes[roots[base]].size >= MAX_HEAP_SIZE || used >= MAX_NODES { return Err(()); }
            let singleton = used;
            used += 1;
            nodes[singleton] = HeapNode { key, npl: 0, size: 1, ..HeapNode::default() };
            roots[operation + 1] = meld(&mut nodes, &mut used, roots[base], singleton).ok_or(())?;
            if nodes[roots[operation + 1]].size > MAX_HEAP_SIZE { return Err(()); }
        } else if kind == 1 {
            if cursor + 2 > input.len() { return Err(()); }
            let (left64, right64) = (input[cursor], input[cursor + 1]);
            cursor += 2;
            if left64 < 0 || left64 > operation as i64 || right64 < 0 || right64 > operation as i64 { return Err(()); }
            let (left_version, right_version) = (left64 as usize, right64 as usize);
            if nodes[roots[left_version]].size + nodes[roots[right_version]].size > MAX_HEAP_SIZE { return Err(()); }
            roots[operation + 1] = meld(&mut nodes, &mut used, roots[left_version], roots[right_version]).ok_or(())?;
            if nodes[roots[operation + 1]].size > MAX_HEAP_SIZE { return Err(()); }
        } else if kind == 2 {
            if cursor + 1 > input.len() { return Err(()); }
            let version64 = input[cursor];
            cursor += 1;
            if version64 < 0 || version64 > operation as i64 { return Err(()); }
            let root = roots[version64 as usize];
            if root == 0 {
                roots[operation + 1] = 0;
                rank_sum += 20_001;
                rank_xor ^= 20_001;
            } else {
                let rank = nodes[root].key + 10_000;
                rank_sum += rank;
                rank_xor ^= rank;
                let left = nodes[root].left;
                let right = nodes[root].right;
                roots[operation + 1] = meld(&mut nodes, &mut used, left, right).ok_or(())?;
                if nodes[roots[operation + 1]].size > MAX_HEAP_SIZE { return Err(()); }
            }
        } else if kind == 3 {
            if cursor + 1 > input.len() { return Err(()); }
            let version64 = input[cursor];
            cursor += 1;
            if version64 < 0 || version64 > operation as i64 { return Err(()); }
            let root = roots[version64 as usize];
            roots[operation + 1] = root;
            let rank = if root == 0 { 20_001 } else { nodes[root].key + 10_000 };
            rank_sum += rank;
            rank_xor ^= rank;
        } else {
            return Err(());
        }
    }
    if cursor != input.len() { return Err(()); }
    Ok((rank_sum << 15) | rank_xor)
}

#[no_mangle]
pub unsafe extern "C" fn persistent_leftist_heap(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_INPUT_WORDS { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
