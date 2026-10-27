const MAX_LEAVES: usize = 8;
const MAX_NODES: usize = 15;
const MAX_CANDIDATES: usize = 256;
const MAX_INPUT: usize = 32;
const OUTPUT_BYTES: usize = 32;

#[derive(Clone, Copy, Default)]
struct Candidate { height: i64, width: i64, mask: u64 }

#[derive(Clone, Copy)]
struct Node {
    op: i64,
    left: usize,
    right: usize,
    count: usize,
    candidates: [Candidate; MAX_CANDIDATES],
}

impl Default for Node {
    fn default() -> Self {
        Self { op: -1, left: 0, right: 0, count: 0,
            candidates: [Candidate::default(); MAX_CANDIDATES] }
    }
}

fn mask_lex_less(a: u64, b: u64, leaves: usize) -> bool {
    for bit in 0..leaves {
        let av = (a >> bit) & 1;
        let bv = (b >> bit) & 1;
        if av != bv { return av < bv; }
    }
    false
}

fn prune(node: &mut Node, leaves: usize) {
    let mut dominated = [false; MAX_CANDIDATES];
    for i in 0..node.count {
        let a = node.candidates[i];
        for j in 0..node.count {
            if i == j { continue; }
            let b = node.candidates[j];
            if b.height <= a.height && b.width <= a.width &&
                (b.height < a.height || b.width < a.width ||
                 mask_lex_less(b.mask, a.mask, leaves) || (b.mask == a.mask && j < i)) {
                dominated[i] = true;
                break;
            }
        }
    }
    let mut kept = 0;
    for i in 0..node.count {
        if !dominated[i] {
            node.candidates[kept] = node.candidates[i];
            kept += 1;
        }
    }
    node.count = kept;
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    core::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8);
}

#[no_mangle]
pub unsafe extern "C" fn slicing_floorplan_stockmeyer(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let values = core::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_LEAVES as i64 { return -1; }
    let leaves = values[0] as usize;
    let mut nodes = [Node::default(); MAX_NODES];
    let mut stack = [0usize; MAX_NODES];
    let (mut stack_size, mut node_count, mut leaf_count, mut internal_count) = (0, 0, 0, 0);
    let mut position = 1;
    while position < length {
        let token = values[position];
        position += 1;
        if token == 2 {
            if position + 2 > length || leaf_count >= leaves || node_count >= MAX_NODES { return -1; }
            let height = values[position];
            let width = values[position + 1];
            position += 2;
            if !(1..=20).contains(&height) || !(1..=20).contains(&width) { return -1; }
            nodes[node_count].op = 2;
            nodes[node_count].candidates[0] = Candidate { height, width, mask: 0 };
            nodes[node_count].candidates[1] = Candidate { height: width, width: height, mask: 1u64 << leaf_count };
            nodes[node_count].count = 2;
            prune(&mut nodes[node_count], leaves);
            stack[stack_size] = node_count;
            stack_size += 1;
            node_count += 1;
            leaf_count += 1;
        } else if token == 0 || token == 1 {
            if stack_size < 2 || internal_count >= leaves - 1 || node_count >= MAX_NODES { return -1; }
            stack_size -= 1;
            let right = stack[stack_size];
            stack_size -= 1;
            let left = stack[stack_size];
            if nodes[right].op == token { return -1; }
            nodes[node_count].op = token;
            nodes[node_count].left = left;
            nodes[node_count].right = right;
            for i in 0..nodes[left].count {
                for j in 0..nodes[right].count {
                    if nodes[node_count].count >= MAX_CANDIDATES { return -1; }
                    let a = nodes[left].candidates[i];
                    let b = nodes[right].candidates[j];
                    let candidate = if token == 0 {
                        Candidate { height: a.height.max(b.height), width: a.width + b.width,
                            mask: a.mask | b.mask }
                    } else {
                        Candidate { height: a.height + b.height, width: a.width.max(b.width),
                            mask: a.mask | b.mask }
                    };
                    let slot = nodes[node_count].count;
                    nodes[node_count].candidates[slot] = candidate;
                    nodes[node_count].count += 1;
                }
            }
            prune(&mut nodes[node_count], leaves);
            stack[stack_size] = node_count;
            stack_size += 1;
            node_count += 1;
            internal_count += 1;
        } else { return -1; }
    }
    if position != length || leaf_count != leaves || internal_count != leaves - 1 ||
        node_count != 2 * leaves - 1 || stack_size != 1 { return -1; }
    let root = nodes[stack[0]];
    if root.count == 0 { return -1; }
    let mut best = root.candidates[0];
    for i in 1..root.count {
        let candidate = root.candidates[i];
        let area = candidate.height * candidate.width;
        let best_area = best.height * best.width;
        if area < best_area || (area == best_area && (candidate.height < best.height ||
            (candidate.height == best.height && (candidate.width < best.width ||
            (candidate.width == best.width && mask_lex_less(candidate.mask, best.mask, leaves)))))) {
            best = candidate;
        }
    }
    if output.is_null() || capacity < OUTPUT_BYTES { return -2; }
    let mut staged = [0u8; OUTPUT_BYTES];
    store_i64_le(staged.as_mut_ptr(), 0, best.height * best.width);
    store_i64_le(staged.as_mut_ptr(), 8, best.height);
    store_i64_le(staged.as_mut_ptr(), 16, best.width);
    store_i64_le(staged.as_mut_ptr(), 24, best.mask as i64);
    core::ptr::copy_nonoverlapping(staged.as_ptr(), output, OUTPUT_BYTES);
    OUTPUT_BYTES as i64
}
