#[no_mangle]
pub unsafe extern "C" fn undirected_cycle_check_bfs(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=514).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=32).contains(&values[0]) || !(0..=256).contains(&values[1]) { return -1; }
    let (n, m) = (values[0] as usize, values[1] as usize);
    if length != 2 + 2 * m { return -1; }
    let mut adjacent = [[false; 32]; 32];
    for i in 0..m {
        let (a, b) = (values[2 + 2 * i], values[3 + 2 * i]);
        if a < 0 || b < 0 || a >= n as i64 || b >= n as i64 { return -1; }
        let (a, b) = (a as usize, b as usize);
        if adjacent[a][b] { return -1; }
        adjacent[a][b] = true; adjacent[b][a] = true;
    }
    let mut visited = [false; 32];
    let mut parent = [0usize; 32];
    let mut queue = [0usize; 32];
    for root in 0..n {
        if visited[root] { continue; }
        let (mut head, mut tail) = (0, 1);
        queue[0] = root; parent[root] = n; visited[root] = true;
        while head < tail {
            let u = queue[head]; head += 1;
            for v in 0..n { if adjacent[u][v] {
                if !visited[v] { visited[v] = true; parent[v] = u; queue[tail] = v; tail += 1; }
                else if v != parent[u] { return 1; }
            }}
        }
    }
    0
}
