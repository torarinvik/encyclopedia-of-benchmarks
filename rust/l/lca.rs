const MAX_NODES: usize = 64;

fn find_root(parent: &mut [usize; MAX_NODES], start: usize) -> usize {
    let mut vertex = start;
    while parent[vertex] != vertex {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    vertex
}

#[no_mangle]
pub extern "C" fn lca(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > 129 { return -1; }
    let a = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=MAX_NODES as i64).contains(&a[0]) { return -1; }
    let n = a[0] as usize;
    if length != 2*n+1 { return -1; }
    let mut dsu = [0usize; MAX_NODES];
    let mut degree = [0usize; MAX_NODES];
    let mut adjacency = [[0usize; MAX_NODES]; MAX_NODES];
    for i in 0..n { dsu[i] = i; }
    let mut pos = 1usize;
    for _ in 0..n-1 {
        let u_arg = a[pos];
        let v_arg = a[pos+1];
        pos += 2;
        if u_arg < 0 || u_arg >= n as i64 || v_arg < 0 || v_arg >= n as i64 || u_arg == v_arg { return -1; }
        let u = u_arg as usize;
        let v = v_arg as usize;
        let ru = find_root(&mut dsu, u);
        let rv = find_root(&mut dsu, v);
        if ru == rv { return -1; }
        dsu[ru] = rv;
        adjacency[u][degree[u]] = v;
        degree[u] += 1;
        adjacency[v][degree[v]] = u;
        degree[v] += 1;
    }
    let qa_arg = a[pos];
    let qb_arg = a[pos+1];
    if qa_arg < 0 || qa_arg >= n as i64 || qb_arg < 0 || qb_arg >= n as i64 { return -1; }
    let component = find_root(&mut dsu, 0);
    for i in 1..n { if find_root(&mut dsu, i) != component { return -1; } }

    let mut parent = [0usize; MAX_NODES];
    let mut depth = [0usize; MAX_NODES];
    let mut stack = [0usize; MAX_NODES];
    let mut seen = [false; MAX_NODES];
    let mut stack_size = 1usize;
    stack[0] = 0;
    seen[0] = true;
    while stack_size > 0 {
        stack_size -= 1;
        let vertex = stack[stack_size];
        for i in 0..degree[vertex] {
            let next = adjacency[vertex][i];
            if !seen[next] {
                seen[next] = true;
                parent[next] = vertex;
                depth[next] = depth[vertex] + 1;
                stack[stack_size] = next;
                stack_size += 1;
            }
        }
    }
    let (mut left, mut right) = (qa_arg as usize, qb_arg as usize);
    if depth[left] < depth[right] { std::mem::swap(&mut left, &mut right); }
    while depth[left] != depth[right] { left = parent[left]; }
    if left == right { return left as i64; }
    while left != right { left = parent[left]; right = parent[right]; }
    left as i64
}
