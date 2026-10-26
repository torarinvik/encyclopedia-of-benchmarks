// Clean-room bounded GARDENIA Forward-Backward-Trim SCC profile.
const MAX_N: usize = 16;
const MAX_M: usize = 64;
const MAX_INPUT: usize = 130;
const MAX_TASKS: usize = 34;

fn reach(adj: &[[bool; MAX_N]; MAX_N], active: u32, pivot: usize,
         reverse: bool, n: usize) -> u32 {
    let mut seen = 1u32 << pivot;
    loop {
        let mut expanded = seen;
        for u in 0..n {
            if seen & (1u32 << u) == 0 || active & (1u32 << u) == 0 { continue; }
            for v in 0..n {
                let edge = if reverse { adj[v][u] } else { adj[u][v] };
                if active & (1u32 << v) != 0 && edge { expanded |= 1u32 << v; }
            }
        }
        if expanded == seen { return seen; }
        seen = expanded;
    }
}

#[no_mangle]
pub unsafe extern "C" fn gardenia_fb_trim_scc(input: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || length != 2 + 2 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mut adj = [[false; MAX_N]; MAX_N];
    for e in 0..m {
        let u64 = *input.add(2 + 2 * e);
        let v64 = *input.add(3 + 2 * e);
        if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        if adj[u][v] { return -1; }
        adj[u][v] = true;
    }
    let output_bytes = 8 * n;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut labels = [0i64; MAX_N];
    let mut tasks = [0u32; MAX_TASKS];
    let mut task_count = 1usize;
    tasks[0] = (1u32 << n) - 1;
    while task_count > 0 {
        task_count -= 1;
        let mut active = tasks[task_count];
        while active != 0 {
            let mut trimmed = 0u32;
            for u in 0..n {
                let ub = 1u32 << u;
                if active & ub == 0 { continue; }
                let mut has_in = false;
                let mut has_out = false;
                for v in 0..n {
                    if active & (1u32 << v) == 0 { continue; }
                    has_out |= adj[u][v];
                    has_in |= adj[v][u];
                }
                if !has_in || !has_out { trimmed |= ub; }
            }
            if trimmed == 0 { break; }
            for u in 0..n { if trimmed & (1u32 << u) != 0 { labels[u] = u as i64; } }
            active &= !trimmed;
        }
        if active == 0 { continue; }
        let pivot = active.trailing_zeros() as usize;
        let forward = reach(&adj, active, pivot, false, n);
        let backward = reach(&adj, active, pivot, true, n);
        let component = forward & backward;
        let representative = component.trailing_zeros() as i64;
        for u in 0..n { if component & (1u32 << u) != 0 { labels[u] = representative; } }
        let children = [active & !(forward | backward), forward & !backward,
                        backward & !forward];
        for child in children {
            if child != 0 {
                if task_count >= MAX_TASKS { return -1; }
                tasks[task_count] = child;
                task_count += 1;
            }
        }
    }
    for u in 0..n {
        let bits = labels[u] as u64;
        for byte in 0..8 { *output.add(8 * u + byte) = (bits >> (8 * byte)) as u8; }
    }
    output_bytes as i64
}
