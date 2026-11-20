/// Exact minimum dominating set by closed-neighborhood branch and bound.
const MAX_N: usize = 12;
const MAX_INPUT: usize = 135;

fn search_mds(closed: &[u16; MAX_N], n: usize, full: u16, covered: u16, chosen: i32, best: i32) -> i32 {
    if chosen >= best { return best; }
    if covered == full { return chosen; }
    let uncovered = full & !covered;
    let uncovered_count = uncovered.count_ones() as i32;
    let mut maximum_gain = 0i32;
    for v in 0..n { maximum_gain = maximum_gain.max((closed[v] & uncovered).count_ones() as i32); }
    let lower_bound = (uncovered_count + maximum_gain - 1) / maximum_gain;
    if chosen + lower_bound >= best { return best; }

    let mut branch = 0usize;
    let mut branch_degree = MAX_N + 1;
    for v in 0..n {
        if uncovered & (1u16 << v) != 0 {
            let degree = closed[v].count_ones() as usize;
            if degree < branch_degree { branch = v; branch_degree = degree; }
        }
    }
    let mut candidates = [0usize; MAX_N];
    let mut gains = [0i32; MAX_N];
    let mut count = 0usize;
    for v in 0..n {
        if closed[branch] & (1u16 << v) == 0 { continue; }
        let gain = (closed[v] & uncovered).count_ones() as i32;
        let mut pos = count;
        while pos > 0 && (gain > gains[pos - 1] || (gain == gains[pos - 1] && v < candidates[pos - 1])) {
            gains[pos] = gains[pos - 1]; candidates[pos] = candidates[pos - 1]; pos -= 1;
        }
        gains[pos] = gain; candidates[pos] = v; count += 1;
    }
    let mut result = best;
    for &v in &candidates[..count] {
        result = search_mds(closed, n, full, covered | closed[v], chosen + 1, result);
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn minimum_dominating_set_branch_bound(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let n64 = words[0]; let m64 = words[1];
    if !(1..=MAX_N as i64).contains(&n64) { return -1; }
    let n = n64 as usize;
    let max_edges = n64 * (n64 - 1) / 2;
    if m64 < 0 || m64 > max_edges || length != 2 + 2 * m64 as usize { return -1; }
    let mut adjacency = [0u16; MAX_N];
    for e in 0..m64 as usize {
        let u64 = words[2 + 2 * e]; let v64 = words[3 + 2 * e];
        if u64 < 0 || v64 < 0 || u64 >= n64 || v64 >= n64 || u64 == v64 { return -1; }
        let u = u64 as usize; let v = v64 as usize; let bit = 1u16 << v;
        if adjacency[u] & bit != 0 { return -1; }
        adjacency[u] |= bit; adjacency[v] |= 1u16 << u;
    }
    let mut closed = [0u16; MAX_N];
    for v in 0..n { closed[v] = adjacency[v] | (1u16 << v); }
    let full = (1u16 << n) - 1;
    let mut covered = 0u16; let mut greedy = 0i32;
    while covered != full {
        let mut vertex = 0usize; let mut gain_best = -1i32;
        for v in 0..n {
            let gain = (closed[v] & !covered).count_ones() as i32;
            if gain > gain_best { vertex = v; gain_best = gain; }
        }
        covered |= closed[vertex]; greedy += 1;
    }
    search_mds(&closed, n, full, 0, 0, greedy) as i64
}
