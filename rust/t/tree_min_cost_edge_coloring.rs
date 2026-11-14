//! Uncompiled matching-sensitivity tree edge-coloring draft.
const INF: i64 = 1_000_000_000_000_000;

fn assignment(d: usize, width: usize, cost: &[[i64; 16]; 16]) -> Option<(i64, [i64; 16])> {
    let (mut row_dual, mut col_dual) = ([0i64; 17], [0i64; 17]);
    let mut owner = [0usize; 17];
    for row in 1..=d {
        let (mut previous, mut used, mut slack) = ([0usize; 17], [false; 17], [INF; 17]);
        owner[0] = row;
        let mut col = 0;
        loop {
            used[col] = true;
            let active = owner[col];
            let (mut step, mut next_col) = (INF, 0);
            for candidate in 1..=width {
                if used[candidate] { continue; }
                let reduced = cost[active-1][candidate-1] - row_dual[active] - col_dual[candidate];
                if reduced < slack[candidate] { slack[candidate] = reduced; previous[candidate] = col; }
                if slack[candidate] < step { step = slack[candidate]; next_col = candidate; }
            }
            if next_col == 0 { return None; }
            for candidate in 0..=width {
                if used[candidate] { row_dual[owner[candidate]] += step; col_dual[candidate] -= step; }
                else if candidate != 0 { slack[candidate] -= step; }
            }
            col = next_col;
            if owner[col] == 0 { break; }
        }
        while col != 0 {
            let parent = previous[col];
            owner[col] = owner[parent];
            col = parent;
        }
    }
    let mut base = 0;
    let mut free = None;
    for col in 0..width {
        if owner[col+1] != 0 { base += cost[owner[col+1]-1][col]; }
        else { free = Some(col); }
    }
    let mut deletion = [0i64; 16];
    if width == d { return Some((base, deletion)); }
    let mut distance = [INF; 16];
    distance[free?] = 0;
    for _ in 0..d {
        let mut updated = distance;
        for col in 0..width {
            if owner[col+1] == 0 { continue; }
            let row = owner[col+1]-1;
            for dest in 0..width {
                if distance[dest] != INF {
                    updated[col] = updated[col].min(cost[row][dest]-cost[row][col]+distance[dest]);
                }
            }
        }
        distance = updated;
    }
    for col in 0..width {
        if distance[col] == INF { return None; }
        deletion[col] = base + distance[col];
    }
    Some((base, deletion))
}

#[no_mangle]
pub unsafe extern "C" fn tree_min_cost_edge_coloring(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=82).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (nv, kv) = (values[0], values[1]);
    if !(1..=64).contains(&nv) || !(1..=16).contains(&kv) { return -1; }
    let (n, k) = (nv as usize, kv as usize);
    if length != n+1+k { return -1; }
    let (mut parents, mut degree, mut child_count) = ([0usize; 64], [0usize; 64], [0usize; 64]);
    for vertex in 1..n {
        let parent = values[1+vertex];
        if parent < 0 || parent >= vertex as i64 { return -1; }
        parents[vertex] = parent as usize;
        degree[parents[vertex]] += 1; degree[vertex] += 1;
    }
    let mut prices = [0i64; 16];
    for c in 0..k {
        let value = values[n+1+c];
        if !(0..=1_000_000).contains(&value) { return -1; }
        prices[c] = value;
    }
    if degree[..n].iter().any(|&d| d > k) { return -2; }
    prices[..k].sort_unstable();
    let mut children = [[0usize; 16]; 64];
    for vertex in 1..n {
        let parent = parents[vertex];
        children[parent][child_count[parent]] = vertex;
        child_count[parent] += 1;
    }
    let mut tables = [[0i64; 16]; 64];
    for vertex in (0..n).rev() {
        let d = child_count[vertex];
        if d == 0 { continue; }
        let saturated_root = vertex == 0 && d == k;
        let width = if saturated_root { d } else { d+1 };
        let mut cost = [[0i64; 16]; 16];
        for row in 0..d {
            let child = children[vertex][row];
            for col in 0..width {
                cost[row][col] = prices[col] + tables[child][col.min(child_count[child])];
            }
        }
        let Some((base, deletion)) = assignment(d, width, &cost) else { return -1; };
        if saturated_root { tables[vertex][0] = base; }
        else { tables[vertex][..width].copy_from_slice(&deletion[..width]); }
    }
    if child_count[0] == k { tables[0][0] } else { tables[0][child_count[0]] }
}
