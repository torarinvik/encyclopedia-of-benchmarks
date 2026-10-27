// Clean-room bounded GOC-MCDS-C construction trace.
const MAX_N: usize = 8;
fn put64(output: *mut u8, position: usize, value: i64) {
    unsafe { core::ptr::copy_nonoverlapping(value.to_le_bytes().as_ptr(), output.add(position), 8); }
}

#[no_mangle]
pub unsafe extern "C" fn routing_cost_constrained_cds_goc_mcds_c(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 17 || *input < 1 || *input > 8 { return -1; }
    let n = *input as usize;
    if length != 1 + 2 * n { return -1; }
    let full = (1u64 << n) - 1;
    let mut adjacency = [0u64; MAX_N];
    let mut ids = [0i64; MAX_N];
    for v in 0..n {
        let mask = *input.add(1 + v);
        ids[v] = *input.add(1 + n + v);
        if mask < 0 || mask as u64 > full || (mask as u64 & (1u64 << v)) != 0 || ids[v] < 1 || ids[v] > 1000 { return -1; }
        adjacency[v] = mask as u64;
        for u in 0..v { if ids[u] == ids[v] { return -1; } }
    }
    for u in 0..n { for v in 0..n { if (adjacency[u] >> v) & 1 != (adjacency[v] >> u) & 1 { return -1; } } }
    let mut reached = 1u64;
    loop {
        let mut expanded = reached;
        for v in 0..n { if (reached >> v) & 1 != 0 { expanded |= adjacency[v]; } }
        if expanded == reached { break; }
        reached = expanded;
    }
    if reached != full { return -1; }

    let mut white = full;
    let mut independent = 0u64;
    while white != 0 {
        let mut black = 0u64;
        for v in 0..n {
            if (white >> v) & 1 == 0 { continue; }
            let mut lower = false;
            for u in 0..n { if (white >> u) & 1 != 0 && (adjacency[v] >> u) & 1 != 0 && ids[u] < ids[v] { lower = true; } }
            if !lower { black |= 1u64 << v; }
        }
        if black == 0 { return -1; }
        independent |= black;
        let mut removed = black;
        for v in 0..n { if (black >> v) & 1 != 0 { removed |= adjacency[v]; } }
        white &= !removed;
    }

    let mut order = [0usize; MAX_N];
    for i in 0..n { order[i] = i; }
    order[..n].sort_by_key(|&v| ids[v]);
    let mut connectors = 0u64;
    for a in 0..n {
        let source = order[a]; if (independent >> source) & 1 == 0 { continue; }
        for b in (a + 1)..n {
            let target = order[b]; if (independent >> target) & 1 == 0 { continue; }
            let mut parent = [-2i32; MAX_N];
            let mut queue = [0usize; MAX_N];
            let (mut head, mut tail) = (0usize, 1usize);
            parent[source] = -1; queue[0] = source;
            while head < tail && parent[target] == -2 {
                let current = queue[head]; head += 1;
                for oi in 0..n {
                    let next = order[oi];
                    if (adjacency[current] >> next) & 1 != 0 && parent[next] == -2 {
                        parent[next] = current as i32; queue[tail] = next; tail += 1;
                    }
                }
            }
            if parent[target] == -2 { return -1; }
            let mut path = [0usize; MAX_N];
            let mut path_length = 0usize;
            let mut current = target;
            while current != source { path[path_length] = current; path_length += 1; current = parent[current] as usize; }
            path[path_length] = source; path_length += 1;
            if path_length <= 4 { for i in 1..(path_length - 1) { connectors |= 1u64 << path[i]; } }
        }
    }
    if output.is_null() || capacity < 16 { return -2; }
    let mut staged = [0u8; 16];
    put64(staged.as_mut_ptr(), 0, independent as i64);
    put64(staged.as_mut_ptr(), 8, (independent | connectors) as i64);
    core::ptr::copy_nonoverlapping(staged.as_ptr(), output, 16);
    16
}
