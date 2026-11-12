const MAX_N: usize = 8;
const MAX_M: usize = 12;
const INF: i64 = 1_000_000_000;

fn solve(input: &[i64]) -> i64 {
    if input.len() < 2 || !(1..=MAX_N as i64).contains(&input[0]) || !(0..=MAX_M as i64).contains(&input[1]) { return -1; }
    let n = input[0] as usize;
    let m = input[1] as usize;
    if input.len() != 2 + 3 * m { return -1; }
    if n == 1 { return if m == 0 { 0 } else { -1 }; }
    if m < n - 1 { return -1; }
    let mut distance = [[INF; MAX_N]; MAX_N];
    let mut seen = [[false; MAX_N]; MAX_N];
    let mut degree = [0usize; MAX_N];
    for u in 0..n { distance[u][u] = 0; }
    let mut total_weight = 0i64;
    for edge in 0..m {
        let u0 = input[2 + 3 * edge];
        let v0 = input[3 + 3 * edge];
        let weight = input[4 + 3 * edge];
        if u0 < 0 || u0 >= n as i64 || v0 < 0 || v0 >= n as i64 || u0 == v0 || !(1..=1000).contains(&weight) { return -1; }
        let u = u0 as usize; let v = v0 as usize;
        if seen[u][v] { return -1; }
        seen[u][v] = true; seen[v][u] = true;
        distance[u][v] = weight; distance[v][u] = weight;
        degree[u] += 1; degree[v] += 1; total_weight += weight;
    }
    for middle in 0..n { for source in 0..n { for target in 0..n {
        let candidate = distance[source][middle] + distance[middle][target];
        if candidate < distance[source][target] { distance[source][target] = candidate; }
    }}}
    if (0..n).any(|vertex| distance[0][vertex] >= INF) { return -1; }
    let mut odd = [0usize; MAX_N];
    let mut odd_count = 0usize;
    for vertex in 0..n { if degree[vertex] & 1 != 0 { odd[odd_count] = vertex; odd_count += 1; } }
    let state_count = 1usize << odd_count;
    let mut pairing = [INF; 1 << MAX_N];
    pairing[0] = 0;
    for mask in 1..state_count {
        let first = mask.trailing_zeros() as usize;
        for partner in first + 1..odd_count {
            let partner_bit = 1usize << partner;
            if mask & partner_bit == 0 { continue; }
            let remaining = mask ^ (1usize << first) ^ partner_bit;
            let candidate = distance[odd[first]][odd[partner]] + pairing[remaining];
            if candidate < pairing[mask] { pairing[mask] = candidate; }
        }
    }
    total_weight + pairing[state_count - 1]
}

#[no_mangle]
pub unsafe extern "C" fn undirected_chinese_postman(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 38 { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
