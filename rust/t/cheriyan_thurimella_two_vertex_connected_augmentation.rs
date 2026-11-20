const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_INPUT: usize = 59;

unsafe fn put(out: *mut u8, at: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *out.add(at + byte) = (bits >> (8 * byte)) as u8; }
}

fn biconnected(n: usize, m: usize, u: &[usize; MAX_M], v: &[usize; MAX_M],
               active: &[bool; MAX_M]) -> bool {
    for removed in 0..n {
        let start = if removed == 0 { 1 } else { 0 };
        let mut seen = [false; MAX_N];
        let mut queue = [0usize; MAX_N];
        let (mut head, mut tail) = (0, 1);
        seen[start] = true;
        queue[0] = start;
        while head < tail {
            let current = queue[head];
            head += 1;
            for edge in 0..m {
                if !active[edge] || u[edge] == removed || v[edge] == removed { continue; }
                let next = if u[edge] == current { v[edge] }
                    else if v[edge] == current { u[edge] } else { n };
                if next < n && !seen[next] {
                    seen[next] = true;
                    queue[tail] = next;
                    tail += 1;
                }
            }
        }
        for vertex in 0..n { if vertex != removed && !seen[vertex] { return false; } }
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn cheriyan_thurimella_two_vertex_connected_augmentation(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(3..=8).contains(&n64) || !(3..=28).contains(&m64)
        || length != 2 + 2 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mut u = [0usize; MAX_M];
    let mut v = [0usize; MAX_M];
    for edge in 0..m {
        let a = *input.add(2 + 2 * edge);
        let b = *input.add(3 + 2 * edge);
        if a < 0 || a >= b || b >= n64 { return -1; }
        u[edge] = a as usize;
        v[edge] = b as usize;
        for prior in 0..edge {
            if u[prior] == u[edge] && v[prior] == v[edge] { return -1; }
        }
    }
    let mut active = [false; MAX_M];
    for edge in 0..m { active[edge] = true; }
    if !biconnected(n, m, &u, &v, &active) { return -1; }

    let states = 1usize << n;
    let mut best = [0i32; 1 << MAX_N];
    let mut choice = [-1i32; 1 << MAX_N];
    for mask in 1..states {
        let first = mask.trailing_zeros() as usize;
        for edge in 0..m {
            let other = if u[edge] == first { v[edge] }
                else if v[edge] == first { u[edge] } else { n };
            if other == n || mask & (1usize << other) == 0 { continue; }
            let rest = mask & !(1usize << first) & !(1usize << other);
            let candidate = 1 + best[rest];
            if candidate > best[mask] {
                best[mask] = candidate;
                choice[mask] = edge as i32;
            }
        }
        let rest = mask & !(1usize << first);
        if best[rest] > best[mask] { best[mask] = best[rest]; choice[mask] = -1; }
    }

    let mut cover = [false; MAX_M];
    let mut covered = [false; MAX_N];
    let mut mask = states - 1;
    while mask != 0 {
        let first = mask.trailing_zeros() as usize;
        let edge = choice[mask];
        if edge < 0 { mask &= !(1usize << first); continue; }
        let edge = edge as usize;
        cover[edge] = true;
        covered[u[edge]] = true;
        covered[v[edge]] = true;
        mask &= !(1usize << u[edge]) & !(1usize << v[edge]);
    }
    for vertex in 0..n {
        if covered[vertex] { continue; }
        for edge in 0..m {
            if u[edge] == vertex || v[edge] == vertex {
                cover[edge] = true;
                covered[u[edge]] = true;
                covered[v[edge]] = true;
                break;
            }
        }
    }
    for edge in 0..m {
        if cover[edge] { continue; }
        active[edge] = false;
        if !biconnected(n, m, &u, &v, &active) { active[edge] = true; }
    }
    let count = (0..m).filter(|&edge| active[edge]).count();
    let bytes = 8 * (1 + 2 * count);
    if output.is_null() || capacity < bytes { return -2; }
    put(output, 0, count as i64);
    let mut slot = 0;
    for edge in 0..m {
        if !active[edge] { continue; }
        put(output, 8 * (1 + 2 * slot), u[edge] as i64);
        put(output, 8 * (2 + 2 * slot), v[edge] as i64);
        slot += 1;
    }
    bytes as i64
}
