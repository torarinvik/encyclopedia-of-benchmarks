const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_INPUT: usize = 59;

unsafe fn put(out: *mut u8, at: usize, value: i64) {
    let bits = value as u64;
    for i in 0..8 { *out.add(at + i) = (bits >> (8 * i)) as u8; }
}
fn connected(n: usize, m: usize, u: &[usize; MAX_M], v: &[usize; MAX_M], skip: isize) -> bool {
    let mut seen = [false; MAX_N]; let mut q = [0usize; MAX_N]; let (mut head, mut tail) = (0, 1);
    q[0] = 0; seen[0] = true;
    while head < tail {
        let x = q[head]; head += 1;
        for e in 0..m {
            if e as isize == skip { continue; }
            let y = if u[e] == x { v[e] } else if v[e] == x { u[e] } else { MAX_N };
            if y < n && !seen[y] { seen[y] = true; q[tail] = y; tail += 1; }
        }
    }
    seen[..n].iter().all(|x| *x)
}
fn earlier(a: usize, b: usize, disc: &[usize; MAX_N]) -> bool { disc[a] < disc[b] }

#[no_mangle]
pub unsafe extern "C" fn two_edge_connected_spanning_subgraph_khuller_vishkin_dfs(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n64 = *input; let m64 = *input.add(1);
    if !(3..=8).contains(&n64) || !(3..=28).contains(&m64) || length != 2 + 2 * m64 as usize { return -1; }
    let n = n64 as usize; let m = m64 as usize;
    let mut u = [0usize; MAX_M]; let mut v = [0usize; MAX_M];
    for e in 0..m {
        let a = *input.add(2 + 2 * e); let b = *input.add(3 + 2 * e);
        if a < 0 || a >= b || b >= n64 { return -1; }
        u[e] = a as usize; v[e] = b as usize;
        for j in 0..e { if u[j] == u[e] && v[j] == v[e] { return -1; } }
    }
    if !connected(n, m, &u, &v, -1) { return -1; }
    for e in 0..m { if !connected(n, m, &u, &v, e as isize) { return -1; } }

    let mut state = [0usize; MAX_N]; let mut disc = [0usize; MAX_N];
    let mut low = [0usize; MAX_N]; let mut low_h = [0usize; MAX_N]; let mut savior = [0usize; MAX_N];
    let mut selected = [false; MAX_M];
    let mut stack_v = [0usize; MAX_N]; let mut stack_parent = [0usize; MAX_N]; let mut stack_cursor = [0usize; MAX_N];
    let (mut tick, mut top) = (1usize, 1usize);
    state[0] = 1; disc[0] = 0; low[0] = 0; low_h[0] = 0; savior[0] = 0;
    stack_v[0] = 0; stack_parent[0] = MAX_N; stack_cursor[0] = 0;
    while top > 0 {
        let frame = top - 1; let x = stack_v[frame]; let parent = stack_parent[frame];
        if stack_cursor[frame] < m {
            let e = stack_cursor[frame]; stack_cursor[frame] += 1;
            let y = if u[e] == x { v[e] } else if v[e] == x { u[e] } else { MAX_N };
            if y == MAX_N { continue; }
            if state[y] == 0 {
                selected[e] = true; state[y] = 1; disc[y] = tick; tick += 1;
                low[y] = y; low_h[y] = y; savior[y] = y;
                stack_v[top] = y; stack_parent[top] = x; stack_cursor[top] = 0; top += 1;
            } else if state[y] == 1 && y != parent && earlier(y, low[x], &disc) {
                low[x] = y; savior[x] = x;
            }
            continue;
        }
        state[x] = 2;
        if parent < n && low_h[x] == x {
            let a = savior[x]; let b = low[x]; let lo = a.min(b); let hi = a.max(b);
            for e in 0..m { if u[e] == lo && v[e] == hi { selected[e] = true; break; } }
            low_h[x] = low[x];
        }
        top -= 1;
        if parent < n {
            if earlier(low[x], low[parent], &disc) { low[parent] = low[x]; savior[parent] = savior[x]; }
            if earlier(low_h[x], low_h[parent], &disc) { low_h[parent] = low_h[x]; }
        }
    }
    let count = selected[..m].iter().filter(|keep| **keep).count();
    let bytes = 8 * (1 + 2 * count);
    if output.is_null() || capacity < bytes { return -2; }
    put(output, 0, count as i64); let mut at = 8;
    for a in 0..n { for b in (a + 1)..n { for e in 0..m {
        if selected[e] && u[e] == a && v[e] == b { put(output, at, a as i64); put(output, at + 8, b as i64); at += 16; }
    } } }
    bytes as i64
}
