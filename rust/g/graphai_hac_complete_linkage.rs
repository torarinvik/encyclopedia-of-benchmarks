// Clean-room bounded GraphAIBench complete-linkage HAC; see package LICENSE.txt.
const MAX_N: usize = 8;
const MAX_M: usize = 24;
const MAX_INPUT: usize = 74;
const MAX_NODES: usize = 15;
const ROOT_PARENT: i64 = 4_294_967_295;

#[no_mangle]
pub unsafe extern "C" fn graphai_hac_complete_linkage(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || length != 2 + 3 * m64 as usize { return -1; }
    let n = n64 as usize; let m = m64 as usize;
    let mut adjacent = [[0i32; MAX_N]; MAX_N];
    let mut used_weight = [false; 33];
    for edge in 0..m {
        let u64 = *input.add(2 + 3 * edge); let v64 = *input.add(3 + 3 * edge);
        let w64 = *input.add(4 + 3 * edge);
        if u64 < 0 || v64 <= u64 || v64 >= n64 || !(1..=32).contains(&w64) { return -1; }
        let u = u64 as usize; let v = v64 as usize; let w = w64 as usize;
        if adjacent[u][v] != 0 || used_weight[w] { return -1; }
        adjacent[u][v] = w as i32; adjacent[v][u] = w as i32; used_weight[w] = true;
    }
    let mut reached = [false; MAX_N]; let mut queue = [0usize; MAX_N];
    reached[0] = true; queue[0] = 0; let mut head = 0; let mut tail = 1;
    while head < tail {
        let u = queue[head]; head += 1;
        for v in 0..n { if adjacent[u][v] != 0 && !reached[v] { reached[v] = true; queue[tail] = v; tail += 1; } }
    }
    if (0..n).any(|v| !reached[v]) { return -1; }
    let node_count = 2 * n - 1; let output_bytes = 16 * node_count;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut active = [false; MAX_N]; let mut current_id = [0usize; MAX_N];
    let mut parent = [ROOT_PARENT; MAX_NODES]; let mut merge_weight = [0i64; MAX_NODES];
    for u in 0..n { active[u] = true; current_id[u] = u; }
    for merge in 0..n - 1 {
        let mut best_u = None; let mut best_v = 0usize; let mut best_weight = 0i32;
        for u in 0..n { if active[u] { for v in u + 1..n {
            if active[v] && adjacent[u][v] > best_weight { best_weight = adjacent[u][v]; best_u = Some(u); best_v = v; }
        } } }
        let Some(u) = best_u else { return -1; };
        let v = best_v;
        let degree_u = (0..n).filter(|&z| active[z] && adjacent[u][z] != 0).count();
        let degree_v = (0..n).filter(|&z| active[z] && adjacent[v][z] != 0).count();
        let (larger, smaller) = if degree_u < degree_v { (v,u) } else { (u,v) };
        let new_id = n + merge;
        parent[current_id[u]] = new_id as i64; parent[current_id[v]] = new_id as i64;
        merge_weight[current_id[u]] = best_weight as i64; merge_weight[current_id[v]] = best_weight as i64;
        let mut merged_weight = [0i32; MAX_N];
        for z in 0..n { if active[z] && z != u && z != v {
            let a = adjacent[u][z]; let b = adjacent[v][z];
            if a != 0 || b != 0 { merged_weight[z] = if a != 0 && b != 0 { a.min(b) } else if a != 0 { a } else { b }; }
        } }
        for z in 0..n { adjacent[u][z] = 0; adjacent[z][u] = 0; adjacent[v][z] = 0; adjacent[z][v] = 0; }
        active[smaller] = false;
        for z in 0..n { if active[z] && z != larger && merged_weight[z] != 0 { adjacent[larger][z] = merged_weight[z]; adjacent[z][larger] = merged_weight[z]; } }
        current_id[larger] = new_id;
    }
    for node in 0..node_count {
        for (slot, value) in [parent[node], merge_weight[node]].iter().enumerate() {
            let bits = *value as u64;
            for byte in 0..8 { *output.add(16 * node + 8 * slot + byte) = (bits >> (8 * byte)) as u8; }
        }
    }
    output_bytes as i64
}
