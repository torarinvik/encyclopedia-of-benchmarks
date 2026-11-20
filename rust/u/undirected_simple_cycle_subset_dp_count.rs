// Clean-room all-length simple-cycle subset DP; see package RIGHTS.md.
#[no_mangle]
pub unsafe extern "C" fn undirected_simple_cycle_subset_dp_count(
    input: *const i64,
    length: usize,
) -> i64 {
    const MAX_N: usize = 14;
    const MAX_M: usize = 91;
    const MAX_STATES: usize = 1 << MAX_N;
    if input.is_null() || length < 2 || length > 185 { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(1..=MAX_N as i64).contains(&n64) || m64 < 0 || m64 > MAX_M as i64 ||
        m64 > n64 * (n64 - 1) / 2 { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    if length != 2 + 2 * m { return -1; }

    let mut adjacency = [[false; MAX_N]; MAX_N];
    let mut neighbors = [[0usize; MAX_N]; MAX_N];
    let mut degree = [0usize; MAX_N];
    let mut previous_u = -1i64;
    let mut previous_v = -1i64;
    for edge in 0..m {
        let u64 = *input.add(2 + 2 * edge);
        let v64 = *input.add(3 + 2 * edge);
        if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || u64 >= v64 { return -1; }
        if edge != 0 && (u64 < previous_u || (u64 == previous_u && v64 <= previous_v)) { return -1; }
        previous_u = u64;
        previous_v = v64;
        let u = u64 as usize;
        let v = v64 as usize;
        adjacency[u][v] = true;
        adjacency[v][u] = true;
        neighbors[u][degree[u]] = v;
        degree[u] += 1;
        neighbors[v][degree[v]] = u;
        degree[v] += 1;
    }

    let mut dp = [[0i64; MAX_N]; MAX_STATES];
    let state_count = 1usize << n;
    for start in 0..n { dp[1usize << start][start] = 1; }
    let mut oriented_cycles = 0i64;
    for mask in 1..state_count {
        let mut start = 0usize;
        while mask & (1usize << start) == 0 { start += 1; }
        let cardinality = mask.count_ones();
        for endpoint in 0..n {
            if mask & (1usize << endpoint) == 0 { continue; }
            let ways = dp[mask][endpoint];
            if ways == 0 { continue; }
            if cardinality >= 3 && adjacency[endpoint][start] { oriented_cycles += ways; }
            for i in 0..degree[endpoint] {
                let next = neighbors[endpoint][i];
                if next > start && mask & (1usize << next) == 0 {
                    dp[mask | (1usize << next)][next] += ways;
                }
            }
        }
    }
    oriented_cycles / 2
}
