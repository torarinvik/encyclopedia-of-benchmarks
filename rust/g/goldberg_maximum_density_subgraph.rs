// Clean-room Goldberg exact maximum-density profile.
const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_NETWORK: usize = 10;

#[no_mangle]
pub unsafe extern "C" fn goldberg_maximum_density_subgraph(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 59 { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(2..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || length != 2 + 2 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mut adjacent = [[false; MAX_N]; MAX_N];
    let mut degree = [0i64; MAX_N];
    let mut edge_u = [0usize; MAX_M];
    let mut edge_v = [0usize; MAX_M];
    for edge in 0..m {
        let u64 = *input.add(2 + 2 * edge);
        let v64 = *input.add(3 + 2 * edge);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        if adjacent[u][v] { return -1; }
        adjacent[u][v] = true;
        adjacent[v][u] = true;
        edge_u[edge] = u;
        edge_v[edge] = v;
        degree[u] += 1;
        degree[v] += 1;
    }
    if m == 0 { return 1; }

    let mut low = 0i64;
    let mut high = m as i64;
    let mut denominator = 1i64;
    let mut best = [false; MAX_N];
    while (high - low) * n64 * (n64 - 1) >= denominator {
        let low2 = 2 * low;
        let high2 = 2 * high;
        let midpoint = low + high;
        let next_denominator = 2 * denominator;
        let source = n;
        let sink = n + 1;
        let network_size = n + 2;
        let mut residual = [[0i64; MAX_NETWORK]; MAX_NETWORK];
        for v in 0..n {
            let source_capacity = (m as i64) * next_denominator;
            residual[source][v] = source_capacity;
            residual[v][sink] = source_capacity + 2 * midpoint - next_denominator * degree[v];
        }
        for edge in 0..m {
            let u = edge_u[edge];
            let v = edge_v[edge];
            residual[u][v] += next_denominator;
            residual[v][u] += next_denominator;
        }
        loop {
            let mut parent = [-1i32; MAX_NETWORK];
            let mut queue = [0usize; MAX_NETWORK];
            let mut head = 0usize;
            let mut tail = 0usize;
            parent[source] = source as i32;
            queue[tail] = source;
            tail += 1;
            while head < tail && parent[sink] == -1 {
                let here = queue[head];
                head += 1;
                for there in 0..network_size {
                    if parent[there] == -1 && residual[here][there] > 0 {
                        parent[there] = here as i32;
                        queue[tail] = there;
                        tail += 1;
                        if there == sink { break; }
                    }
                }
            }
            if parent[sink] == -1 { break; }
            let mut amount = i64::MAX;
            let mut vertex = sink;
            while vertex != source {
                let previous = parent[vertex] as usize;
                amount = amount.min(residual[previous][vertex]);
                vertex = previous;
            }
            vertex = sink;
            while vertex != source {
                let previous = parent[vertex] as usize;
                residual[previous][vertex] -= amount;
                residual[vertex][previous] += amount;
                vertex = previous;
            }
        }
        let mut reachable = [false; MAX_NETWORK];
        let mut queue = [0usize; MAX_NETWORK];
        let mut head = 0usize;
        let mut tail = 0usize;
        reachable[source] = true;
        queue[tail] = source;
        tail += 1;
        while head < tail {
            let here = queue[head];
            head += 1;
            for there in 0..network_size {
                if !reachable[there] && residual[here][there] > 0 {
                    reachable[there] = true;
                    queue[tail] = there;
                    tail += 1;
                }
            }
        }
        let mut selected = [false; MAX_N];
        let mut any = false;
        for v in 0..n { selected[v] = reachable[v]; any |= selected[v]; }
        if any { best = selected; low = midpoint; high = high2; }
        else { low = low2; high = midpoint; }
        denominator = next_denominator;
    }
    let mut vertex_count = 0i64;
    let mut edge_count = 0i64;
    for v in 0..n { if best[v] { vertex_count += 1; } }
    if vertex_count == 0 { return 1; }
    for edge in 0..m { if best[edge_u[edge]] && best[edge_v[edge]] { edge_count += 1; } }
    let mut a = edge_count;
    let mut b = vertex_count;
    while b != 0 { let r = a % b; a = b; b = r; }
    (edge_count / a) * (n64 + 1) + vertex_count / a
}
