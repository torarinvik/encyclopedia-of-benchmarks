// Clean-room bounded GBBS Tarjan-Vishkin biconnectivity profile.
const N: usize = 12;
const M: usize = 24;
const INPUT: usize = 2 + 2 * M;

fn tree_edge(u: usize, v: usize, parent: &[usize; N]) -> bool {
    parent[u] == v || parent[v] == u
}
fn critical_edge(u: usize, v: usize, parent: &[usize; N], critical: &[bool; N]) -> bool {
    if parent[u] == v { return critical[u]; }
    if parent[v] == u { return critical[v]; }
    false
}
fn parents_bfs(n: usize, adj: &[[bool; N]; N], parent: &mut [usize; N], seen: &mut [bool; N]) {
    let mut frontier = [0usize; N];
    let mut next = [0usize; N];
    let mut candidate = [0usize; N];
    for root in 0..n {
        if seen[root] { continue; }
        let mut count = 1;
        frontier[0] = root;
        parent[root] = root;
        seen[root] = true;
        while count != 0 {
            let mut has = [false; N];
            for i in 0..count {
                let v = frontier[i];
                for u in 0..n {
                    if adj[v][u] && !seen[u] {
                        if !has[u] || v < candidate[u] { candidate[u] = v; }
                        has[u] = true;
                    }
                }
            }
            let mut next_count = 0;
            for u in 0..n {
                if has[u] {
                    parent[u] = candidate[u];
                    seen[u] = true;
                    next[next_count] = u;
                    next_count += 1;
                }
            }
            frontier[..next_count].copy_from_slice(&next[..next_count]);
            count = next_count;
        }
    }
}
fn preorder(n: usize, parent: &[usize; N], pn: &mut [usize; N],
            order: &mut [usize; N], size: &mut [usize; N]) {
    let mut stack = [0usize; N];
    let mut global = 0;
    for root in 0..n {
        if parent[root] != root { continue; }
        let (mut top, mut count, begin) = (0usize, 0usize, global);
        stack[top] = root;
        top += 1;
        while top != 0 {
            top -= 1;
            let v = stack[top];
            pn[v] = count;
            count += 1;
            order[global] = v;
            global += 1;
            for child in (0..n).rev() {
                if child != v && parent[child] == v {
                    stack[top] = child;
                    top += 1;
                }
            }
        }
        for i in (begin..global).rev() {
            let v = order[i];
            if parent[v] != v { size[parent[v]] += size[v]; }
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn gbbs_biconnectivity(input: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(1..=N as i64).contains(&n64) || !(0..=M as i64).contains(&m64)
        || length != 2 + 2 * m64 as usize { return -1; }
    let (n, m) = (n64 as usize, m64 as usize);
    let mut adj = [[false; N]; N];
    for e in 0..m {
        let u64 = *input.add(2 + 2 * e);
        let v64 = *input.add(3 + 2 * e);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1; }
        let (u, v) = (u64 as usize, v64 as usize);
        if adj[u][v] { return -1; }
        adj[u][v] = true;
        adj[v][u] = true;
    }
    if output.is_null() || capacity < m { return -2; }
    let mut parent = [0usize; N];
    let mut pn = [0usize; N];
    let mut order = [0usize; N];
    let mut size = [1usize; N];
    let mut seen = [false; N];
    let mut critical = [false; N];
    for v in 0..n { parent[v] = v; }
    parents_bfs(n, &adj, &mut parent, &mut seen);
    preorder(n, &parent, &mut pn, &mut order, &mut size);
    let mut low = pn;
    let mut high = [0usize; N];
    for v in 0..n { high[v] = pn[v] + size[v] - 1; }
    for e in 0..m {
        let u = *input.add(2 + 2 * e) as usize;
        let v = *input.add(3 + 2 * e) as usize;
        if !tree_edge(u, v, &parent) {
            if pn[u] < low[v] { low[v] = pn[u]; } else if pn[u] > high[v] { high[v] = pn[u]; }
            if pn[v] < low[u] { low[u] = pn[v]; } else if pn[v] > high[u] { high[u] = pn[v]; }
        }
    }
    for i in (0..n).rev() {
        let v = order[i];
        if parent[v] != v {
            let p = parent[v];
            low[p] = low[p].min(low[v]);
            high[p] = high[p].max(high[v]);
        }
    }
    for v in 0..n {
        let p = parent[v];
        if v != p && low[v] >= pn[p] && high[v] < pn[p] + size[p] { critical[v] = true; }
    }
    let mut comp = [usize::MAX; N];
    let mut queue = [0usize; N];
    for root in 0..n {
        if comp[root] != usize::MAX { continue; }
        let (mut head, mut tail) = (0usize, 0usize);
        comp[root] = root;
        queue[tail] = root;
        tail += 1;
        while head < tail {
            let v = queue[head];
            head += 1;
            for u in 0..n {
                if adj[v][u] && !critical_edge(v, u, &parent, &critical) && comp[u] == usize::MAX {
                    comp[u] = root;
                    queue[tail] = u;
                    tail += 1;
                }
            }
        }
    }
    let mut raw = [0usize; M];
    for e in 0..m {
        let u = *input.add(2 + 2 * e) as usize;
        let v = *input.add(3 + 2 * e) as usize;
        raw[e] = if parent[u] == v && critical[u] { comp[u] }
            else if parent[v] == u && critical[v] { comp[v] }
            else { comp[u] };
    }
    for e in 0..m {
        let mut label = m;
        for j in 0..m { if raw[j] == raw[e] { label = label.min(j); } }
        *output.add(e) = label as u8;
    }
    m as i64
}
