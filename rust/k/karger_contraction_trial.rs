fn root(parent: &[usize; 8], mut vertex: usize) -> usize {
    while parent[vertex] != vertex { vertex = parent[vertex]; }
    vertex
}

#[no_mangle]
pub unsafe extern "C" fn karger_contraction_trial(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=57).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(2..=8).contains(&values[0]) || !(1..=24).contains(&values[1]) { return -1; }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if length != 2 + 2 * m + n - 2 { return -1; }
    let mut edges = [(0usize, 0usize); 24];
    let mut parent = [0usize; 8];
    for (i, slot) in parent[..n].iter_mut().enumerate() { *slot = i; }
    for i in 0..m {
        let (a, b) = (values[2 + 2 * i], values[3 + 2 * i]);
        if a < 0 || b < 0 || a >= n as i64 || b >= n as i64 || a == b { return -1; }
        edges[i] = (a as usize, b as usize);
        let left = root(&parent, a as usize);
        let right = root(&parent, b as usize);
        parent[left] = right;
    }
    let initial = root(&parent, 0);
    if (1..n).any(|i| root(&parent, i) != initial) { return -1; }
    for (i, slot) in parent[..n].iter_mut().enumerate() { *slot = i; }
    for step in 0..n - 2 {
        let live = edges[..m].iter().filter(|&&(u, v)| root(&parent, u) != root(&parent, v)).count();
        let rank = values[2 + 2 * m + step];
        if rank < 0 || rank >= live as i64 { return -1; }
        let mut remaining = rank as usize;
        for &(u, v) in &edges[..m] {
            let left = root(&parent, u);
            let right = root(&parent, v);
            if left == right { continue; }
            if remaining == 0 { parent[left] = right; break; }
            remaining -= 1;
        }
    }
    edges[..m].iter().filter(|&&(u, v)| root(&parent, u) != root(&parent, v)).count() as i64
}
