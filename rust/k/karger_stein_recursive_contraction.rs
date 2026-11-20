//! Independently authored draft; not compiled or run.
fn root(parent: &[usize; 12], mut vertex: usize) -> usize {
    while parent[vertex] != vertex { vertex = parent[vertex]; }
    vertex
}

fn solve(edges: &[(usize, usize)], tape: &[i64], position: &mut usize,
         parent: &[usize; 12], n: usize, components: usize) -> Option<usize> {
    if components <= 6 {
        let mut index = [0usize; 12];
        let mut count = 0;
        for i in 0..n {
            if parent[i] == i { index[i] = count; count += 1; }
        }
        let mut best = edges.len() + 1;
        for mask in 0..((1usize << (components - 1)) - 1) {
            let side = (mask << 1) | 1;
            let cut = edges.iter().filter(|&&(u, v)| {
                let a = index[root(parent, u)];
                let b = index[root(parent, v)];
                (side >> a) & 1 != (side >> b) & 1
            }).count();
            best = best.min(cut);
        }
        return Some(best);
    }
    const TARGET: [usize; 13] = [0,0,0,0,0,0,0,6,7,8,9,9,10];
    let mut best = edges.len() + 1;
    for _ in 0..2 {
        let mut next = *parent;
        for _ in TARGET[components]..components {
            let live = edges.iter().filter(|&&(u, v)| root(&next, u) != root(&next, v)).count();
            let mut rank = *tape.get(*position)?;
            *position += 1;
            if rank < 0 || rank >= live as i64 { return None; }
            for &(u, v) in edges {
                let a = root(&next, u);
                let b = root(&next, v);
                if a == b { continue; }
                if rank == 0 { next[b] = a; break; }
                rank -= 1;
            }
        }
        best = best.min(solve(edges, tape, position, &next, n, TARGET[components])?);
    }
    Some(best)
}

#[no_mangle]
pub unsafe extern "C" fn karger_stein_recursive_contraction(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(3..=132).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(2..=12).contains(&values[0]) || !(1..=32).contains(&values[1])
        || !(0..=64).contains(&values[2]) { return -1; }
    let (n, m, q) = (values[0] as usize, values[1] as usize, values[2] as usize);
    if length != 3 + 2*m + q { return -1; }
    let mut edges = [(0usize, 0usize); 32];
    let mut parent = [0usize; 12];
    for (i, p) in parent.iter_mut().enumerate() { *p = i; }
    for i in 0..m {
        let (u, v) = (values[3+2*i], values[4+2*i]);
        if u < 0 || v < 0 || u >= n as i64 || v >= n as i64 || u == v { return -1; }
        edges[i] = (u as usize, v as usize);
        let a = root(&parent, u as usize);
        let b = root(&parent, v as usize);
        parent[b] = a;
    }
    if (1..n).any(|v| root(&parent, v) != root(&parent, 0)) { return -1; }
    for (i, p) in parent.iter_mut().enumerate() { *p = i; }
    let mut position = 0;
    let result = solve(&edges[..m], &values[3+2*m..], &mut position, &parent, n, n);
    match result {
        Some(value) if position == q => value as i64,
        _ => -1,
    }
}
