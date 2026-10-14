/// Heapsort packed undirected edges, then build an MST with union by rank.
fn sift_down(keys: &mut [i64], mut root: usize, end: usize) {
    while root < end / 2 {
        let mut child = root * 2 + 1;
        if child + 1 < end && keys[child] < keys[child + 1] { child += 1; }
        if keys[root] >= keys[child] { break; }
        keys.swap(root, child);
        root = child;
    }
}
fn find_root(parent: &mut [usize; 64], mut node: usize) -> usize {
    while parent[node] != node { parent[node] = parent[parent[node]]; node = parent[node]; }
    node
}
#[no_mangle]
pub extern "C" fn kruskal(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 12_290 { return -2; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] < 0 || values[0] > 64 || values[1] < 0 || values[1] > 4096 { return -2; }
    let vertices = values[0] as usize;
    let edges = values[1] as usize;
    if length != 2 + 3 * edges || (vertices == 0 && edges != 0) { return -2; }
    if vertices == 0 { return 0; }
    let mut keys = [0i64; 4096];
    for edge in 0..edges {
        let (mut u, mut v, weight) = (values[2 + 3 * edge], values[3 + 3 * edge], values[4 + 3 * edge]);
        if u < 0 || v < 0 || u as u64 >= vertices as u64 || v as u64 >= vertices as u64 || !(0..=2_147_483_647).contains(&weight) { return -2; }
        if u > v { std::mem::swap(&mut u, &mut v); }
        keys[edge] = weight * 4096 + u * 64 + v;
    }
    let keys = &mut keys[..edges];
    for start in (0..edges / 2).rev() { sift_down(keys, start, edges); }
    for end in (1..edges).rev() { keys.swap(0, end); sift_down(keys, 0, end); }
    let mut parent = [0usize; 64]; let mut rank = [0usize; 64];
    for vertex in 0..vertices { parent[vertex] = vertex; }
    let mut selected = 0usize; let mut total = 0i64;
    for &key in keys.iter() {
        if selected + 1 >= vertices { break; }
        let u = ((key % 4096) / 64) as usize; let v = (key % 64) as usize;
        let root_u = find_root(&mut parent, u); let root_v = find_root(&mut parent, v);
        if root_u != root_v {
            total += key / 4096; selected += 1;
            if rank[root_u] < rank[root_v] { parent[root_u] = root_v; }
            else if rank[root_u] > rank[root_v] { parent[root_v] = root_u; }
            else { parent[root_v] = root_u; rank[root_u] += 1; }
        }
    }
    if selected + 1 == vertices { total } else { -1 }
}
