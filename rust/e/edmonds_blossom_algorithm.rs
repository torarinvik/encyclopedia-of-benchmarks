/// Edmonds blossom contraction for maximum matching in a small general graph.
const MAX_VERTICES: usize = 20;
const MAX_EDGES: usize = MAX_VERTICES * (MAX_VERTICES - 1) / 2;

fn lca(mut a: usize, mut b: usize, base: &[usize; MAX_VERTICES],
       parent: &[i32; MAX_VERTICES], mate: &[i32; MAX_VERTICES]) -> usize {
    let mut path = [false; MAX_VERTICES];
    loop {
        a = base[a];
        path[a] = true;
        if mate[a] == -1 { break; }
        a = parent[mate[a] as usize] as usize;
    }
    loop {
        b = base[b];
        if path[b] { return b; }
        b = parent[mate[b] as usize] as usize;
    }
}

fn mark_path(mut v: usize, b: usize, mut child: usize,
             base: &[usize; MAX_VERTICES], parent: &mut [i32; MAX_VERTICES],
             mate: &[i32; MAX_VERTICES], blossom: &mut [bool; MAX_VERTICES]) {
    while base[v] != b {
        blossom[base[v]] = true;
        blossom[base[mate[v] as usize]] = true;
        parent[v] = child as i32;
        child = mate[v] as usize;
        v = parent[child] as usize;
    }
}

fn find_path(root: usize, n: usize, graph: &[[bool; MAX_VERTICES]; MAX_VERTICES],
             mate: &[i32; MAX_VERTICES], parent: &mut [i32; MAX_VERTICES],
             base: &mut [usize; MAX_VERTICES]) -> i32 {
    let mut used = [false; MAX_VERTICES];
    let mut queue = [0usize; MAX_VERTICES];
    let mut head = 0;
    let mut tail = 0;
    for i in 0..n { parent[i] = -1; base[i] = i; }
    queue[tail] = root; tail += 1; used[root] = true;
    while head < tail {
        let v = queue[head]; head += 1;
        for u in 0..n {
            if !graph[v][u] || base[v] == base[u] || mate[v] == u as i32 { continue; }
            if u == root || (mate[u] != -1 && parent[mate[u] as usize] != -1) {
                let cur = lca(v, u, base, parent, mate);
                let mut blossom = [false; MAX_VERTICES];
                mark_path(v, cur, u, base, parent, mate, &mut blossom);
                mark_path(u, cur, v, base, parent, mate, &mut blossom);
                for i in 0..n {
                    if blossom[base[i]] {
                        base[i] = cur;
                        if !used[i] { used[i] = true; queue[tail] = i; tail += 1; }
                    }
                }
            } else if parent[u] == -1 {
                parent[u] = v as i32;
                if mate[u] == -1 { return u as i32; }
                let next = mate[u] as usize;
                used[next] = true; queue[tail] = next; tail += 1;
            }
        }
    }
    -1
}

#[no_mangle]
pub extern "C" fn edmonds_blossom_algorithm(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let n_value = unsafe { *input };
    let m_value = unsafe { *input.add(1) };
    if n_value < 0 || n_value > MAX_VERTICES as i64 || m_value < 0 || m_value > MAX_EDGES as i64 {
        return -1;
    }
    let n = n_value as usize;
    let m = m_value as usize;
    if length != 2 + 2 * m { return -1; }
    let mut graph = [[false; MAX_VERTICES]; MAX_VERTICES];
    for edge in 0..m {
        let a = unsafe { *input.add(2 + 2 * edge) };
        let b = unsafe { *input.add(3 + 2 * edge) };
        if a < 0 || a >= n as i64 || b < 0 || b >= n as i64 || a == b { return -1; }
        graph[a as usize][b as usize] = true;
        graph[b as usize][a as usize] = true;
    }
    let mut mate = [-1i32; MAX_VERTICES];
    let mut parent = [-1i32; MAX_VERTICES];
    let mut base = [0usize; MAX_VERTICES];
    let mut answer = 0i64;
    for i in 0..n {
        if mate[i] != -1 { continue; }
        let mut v = find_path(i, n, &graph, &mate, &mut parent, &mut base);
        while v != -1 {
            let vertex = v as usize;
            let pv = parent[vertex] as usize;
            let next = mate[pv];
            mate[vertex] = pv as i32;
            mate[pv] = vertex as i32;
            v = next;
        }
        if mate[i] != -1 { answer += 1; }
    }
    answer
}
