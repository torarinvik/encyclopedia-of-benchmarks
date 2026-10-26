// Clean-room bounded GBBS Shiloach-Vishkin spanning-forest profile.
const N: usize = 12;
const M: usize = 24;
const INPUT: usize = 2 + 2 * M;

fn find_root(parent: &mut [usize; N], mut vertex: usize) -> usize {
    while parent[vertex] != vertex {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    vertex
}

#[no_mangle]
pub unsafe extern "C" fn gbbs_shiloach_vishkin_spanning_forest(input: *const i64,
        length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if n64 < 1 || n64 > N as i64 || m64 < 0 || m64 > M as i64
        || length != 2 + 2 * m64 as usize { return -1; }
    let (n, m) = (n64 as usize, m64 as usize);
    let mut seen = [[false; N]; N];
    let mut edge_u = [0usize; M];
    let mut edge_v = [0usize; M];
    for edge in 0..m {
        let u64 = *input.add(2 + 2 * edge);
        let v64 = *input.add(3 + 2 * edge);
        if u64 < 0 || u64 >= n64 || v64 <= u64 || v64 >= n64 { return -1; }
        let (u, v) = (u64 as usize, v64 as usize);
        if seen[u][v] { return -1; }
        seen[u][v] = true;
        edge_u[edge] = u;
        edge_v[edge] = v;
    }
    if output.is_null() || capacity < m { return -2; }

    let mut parent = [0usize; N];
    let mut previous = [0usize; N];
    let mut next_parent = [0usize; N];
    let mut best_lower = [0usize; N];
    let mut selected = [0u8; M];
    for vertex in 0..n { parent[vertex] = vertex; }
    for _round in 0..n {
        for vertex in 0..n {
            previous[vertex] = find_root(&mut parent, vertex);
            next_parent[vertex] = previous[vertex];
            best_lower[vertex] = n;
        }
        for edge in 0..m {
            let (root_u, root_v) = (previous[edge_u[edge]], previous[edge_v[edge]]);
            if root_u == root_v { continue; }
            let (lower, higher) = if root_u < root_v { (root_u, root_v) } else { (root_v, root_u) };
            if previous[higher] == higher && lower < best_lower[higher] { best_lower[higher] = lower; }
        }
        let mut changed = false;
        for higher in 0..n {
            let lower = best_lower[higher];
            if lower == n { continue; }
            next_parent[higher] = lower;
            changed = true;
            for edge in 0..m {
                let (root_u, root_v) = (previous[edge_u[edge]], previous[edge_v[edge]]);
                if (root_u == higher && root_v == lower) || (root_u == lower && root_v == higher) {
                    selected[edge] = 1;
                    break;
                }
            }
        }
        for vertex in 0..n { parent[vertex] = find_root(&mut next_parent, vertex); }
        if !changed { break; }
    }
    for edge in 0..m { *output.add(edge) = selected[edge]; }
    m as i64
}
