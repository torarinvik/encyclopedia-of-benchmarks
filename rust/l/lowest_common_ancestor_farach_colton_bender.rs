const MAX_NODES: usize = 256;
const MAX_QUERIES: usize = 1024;
const MAX_ARCS: usize = 510;
const MAX_EULER: usize = 2 * MAX_NODES - 1;
const MAX_BLOCKS: usize = 128;
const MAX_LEVELS: usize = 8;
const MAX_MICRO: usize = 4;

fn shallower(a: u16, b: u16, depth: &[u16; MAX_EULER]) -> u16 {
    if depth[a as usize] != depth[b as usize] {
        if depth[a as usize] < depth[b as usize] { a } else { b }
    } else if a < b { a } else { b }
}

fn range_minimum(first: u16, last: u16, euler_count: usize, block_size: usize,
    depth: &[u16; MAX_EULER], pattern: &[u8; MAX_BLOCKS],
    micro: &[[[u8; MAX_MICRO]; MAX_MICRO]; 8],
    macro_table: &[[u16; MAX_BLOCKS]; MAX_LEVELS], logs: &[u8; MAX_BLOCKS + 1]) -> u16 {
    let (ba, bb) = (first as usize / block_size, last as usize / block_size);
    let (oa, ob) = (first as usize % block_size, last as usize % block_size);
    if ba == bb { return (ba * block_size + micro[pattern[ba] as usize][oa][ob]) as u16; }
    let base_a = ba * block_size;
    let base_b = bb * block_size;
    let len_a = (euler_count - base_a).min(block_size);
    let mut best = (base_a + micro[pattern[ba] as usize][oa][len_a - 1]) as u16;
    best = shallower(best, (base_b + micro[pattern[bb] as usize][0][ob]) as u16, depth);
    if bb > ba + 1 {
        let lo = ba + 1;
        let hi = bb - 1;
        let count = hi - lo + 1;
        let level = logs[count] as usize;
        let span = 1usize << level;
        best = shallower(best, macro_table[level][lo], depth);
        best = shallower(best, macro_table[level][hi - span + 1], depth);
    }
    best
}

#[no_mangle]
pub unsafe extern "C" fn lowest_common_ancestor_farach_colton_bender(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_NODES as i64).contains(&input[0]) { return -1; }
    let n = input[0] as usize;
    if input[1] < 0 || input[1] >= n as i64 || input[2] != (n - 1) as i64 ||
        input[3] < 0 || input[3] > MAX_QUERIES as i64 { return -1; }
    let edge_count = input[2] as usize;
    let query_count = input[3] as usize;
    let query_offset = 4 + 2 * edge_count;
    if length != query_offset + 2 * query_count { return -1; }
    let root = input[1] as usize;

    let mut head = [-1i32; MAX_NODES];
    let mut arc_to = [0usize; MAX_ARCS];
    let mut arc_next = [-1i32; MAX_ARCS];
    let mut parent = [-2i32; MAX_NODES];
    let mut tree_depth = [0usize; MAX_NODES];
    let mut first = [0usize; MAX_NODES];
    let mut euler = [0u16; MAX_EULER];
    let mut euler_depth = [0u16; MAX_EULER];
    let mut stack_node = [0usize; MAX_NODES];
    let mut stack_arc = [0i32; MAX_NODES];
    let mut arcs = 0usize;
    for edge in 0..edge_count {
        let u = input[4 + 2 * edge];
        let v = input[5 + 2 * edge];
        if u < 0 || u >= n as i64 || v < 0 || v >= n as i64 || u == v { return -1; }
        let (a, b) = (u as usize, v as usize);
        arc_to[arcs] = b; arc_next[arcs] = head[a]; head[a] = arcs as i32; arcs += 1;
        arc_to[arcs] = a; arc_next[arcs] = head[b]; head[b] = arcs as i32; arcs += 1;
    }
    for query in 0..query_count {
        for side in 0..2 {
            let node = input[query_offset + 2 * query + side];
            if node < 0 || node >= n as i64 { return -1; }
        }
    }

    let mut euler_count = 1usize;
    let mut top = 1usize;
    let mut reached = 1usize;
    parent[root] = -1;
    first[root] = 0;
    euler[0] = root as u16;
    stack_node[0] = root;
    stack_arc[0] = head[root];
    while top > 0 {
        let slot = top - 1;
        let node = stack_node[slot];
        let arc = stack_arc[slot];
        if arc < 0 {
            top -= 1;
            if top > 0 {
                let up = stack_node[top - 1];
                euler[euler_count] = up as u16;
                euler_depth[euler_count] = tree_depth[up] as u16;
                euler_count += 1;
            }
            continue;
        }
        stack_arc[slot] = arc_next[arc as usize];
        let neighbor = arc_to[arc as usize];
        if neighbor as i32 == parent[node] { continue; }
        if parent[neighbor] != -2 { return -1; }
        parent[neighbor] = node as i32;
        tree_depth[neighbor] = tree_depth[node] + 1;
        first[neighbor] = euler_count;
        euler[euler_count] = neighbor as u16;
        euler_depth[euler_count] = tree_depth[neighbor] as u16;
        euler_count += 1;
        reached += 1;
        stack_node[top] = neighbor;
        stack_arc[top] = head[neighbor];
        top += 1;
    }
    if reached != n { return -1; }
    if output_capacity < query_count || (query_count != 0 && output.is_null()) { return -2; }

    let mut logarithm = 0usize;
    let mut value = euler_count;
    while value > 1 { value >>= 1; logarithm += 1; }
    let block_size = (logarithm / 2).max(1);
    let block_count = (euler_count + block_size - 1) / block_size;
    let mut micro = [[[0u8; MAX_MICRO]; MAX_MICRO]; 8];
    let mut pattern = [0u8; MAX_BLOCKS];
    let mut logs = [0u8; MAX_BLOCKS + 1];
    let mut macro_table = [[0u16; MAX_BLOCKS]; MAX_LEVELS];
    for shape in 0..(1usize << (block_size - 1)) {
        let mut relative = [0i32; MAX_MICRO];
        for step in 0..block_size.saturating_sub(1) {
            relative[step + 1] = relative[step] + if (shape >> step) & 1 != 0 { 1 } else { -1 };
        }
        for left in 0..block_size {
            for right in left..block_size {
                let mut best = left;
                for at in left + 1..=right {
                    if relative[at] < relative[best] { best = at; }
                }
                micro[shape][left][right] = best as u8;
            }
        }
    }
    for block in 0..block_count {
        let base = block * block_size;
        let end = (base + block_size).min(euler_count);
        let mut best = base as u16;
        for at in base..end.saturating_sub(1) {
            if euler_depth[at + 1] > euler_depth[at] { pattern[block] |= 1 << (at - base); }
            best = shallower(best, (at + 1) as u16, &euler_depth);
        }
        macro_table[0][block] = best;
    }
    for count in 2..=block_count { logs[count] = logs[count / 2] + 1; }
    let mut macro_levels = 1usize;
    while (1usize << macro_levels) <= block_count && macro_levels < MAX_LEVELS {
        let half = 1usize << (macro_levels - 1);
        let span = 2 * half;
        for block in 0..=block_count - span {
            macro_table[macro_levels][block] = shallower(
                macro_table[macro_levels - 1][block], macro_table[macro_levels - 1][block + half], &euler_depth);
        }
        macro_levels += 1;
    }

    let mut answers = [0u8; MAX_QUERIES];
    for query in 0..query_count {
        let u = input[query_offset + 2 * query] as usize;
        let v = input[query_offset + 2 * query + 1] as usize;
        let (mut left, mut right) = (first[u], first[v]);
        if left > right { std::mem::swap(&mut left, &mut right); }
        let at = range_minimum(left as u16, right as u16, euler_count, block_size,
            &euler_depth, &pattern, &micro, &macro_table, &logs);
        answers[query] = euler[at as usize] as u8;
    }
    for query in 0..query_count { *output.add(query) = answers[query]; }
    query_count as i64
}
