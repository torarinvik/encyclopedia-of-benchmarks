// Clean-room DAG-to-bipartite-matching minimum path-cover profile.
const MAX_N: usize = 10;
const MAX_M: usize = 45;

fn augment(adj: &[u16; MAX_N], n: usize, left: usize, used: u16,
           seen: &mut [bool; MAX_N], pair_right: &mut [i32; MAX_N]) -> bool {
    for right in 0..n {
        let bit = 1u16 << right;
        if adj[left] & bit == 0 || used & bit != 0 || seen[right] { continue; }
        seen[right] = true;
        let mate = pair_right[right];
        if mate < 0 || augment(adj, n, mate as usize, used, seen, pair_right) {
            pair_right[right] = left as i32;
            return true;
        }
    }
    false
}

fn maximum_matching(adj: &[u16; MAX_N], n: usize, first: usize, used: u16) -> usize {
    let mut pair_right = [-1i32; MAX_N];
    let mut size = 0usize;
    for left in first..n {
        let mut seen = [false; MAX_N];
        if augment(adj, n, left, used, &mut seen, &mut pair_right) { size += 1; }
    }
    size
}

#[no_mangle]
pub unsafe extern "C" fn dag_minimum_path_cover(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 93 { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if n64 < 1 || n64 > MAX_N as i64 || m64 < 0 || m64 > MAX_M as i64 ||
       length != 2 + 2 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mut adj = [0u16; MAX_N];
    let mut indegree = [0i32; MAX_N];
    for i in 0..m {
        let u64 = *input.add(2 + 2 * i);
        let v64 = *input.add(3 + 2 * i);
        if u64 < 0 || u64 >= n as i64 || v64 < 0 || v64 >= n as i64 || u64 == v64 { return -1; }
        let (u, v) = (u64 as usize, v64 as usize);
        let bit = 1u16 << v;
        if adj[u] & bit != 0 { return -1; }
        adj[u] |= bit; indegree[v] += 1;
    }
    let mut queue = [0usize; MAX_N];
    let (mut head, mut tail) = (0usize, 0usize);
    for v in 0..n { if indegree[v] == 0 { queue[tail] = v; tail += 1; } }
    let mut removed = 0usize;
    while head < tail {
        let u = queue[head]; head += 1; removed += 1;
        for v in 0..n {
            if adj[u] & (1u16 << v) != 0 {
                indegree[v] -= 1;
                if indegree[v] == 0 { queue[tail] = v; tail += 1; }
            }
        }
    }
    if removed != n { return -1; }
    let maximum = maximum_matching(&adj, n, 0, 0);
    let mut successor = [n; MAX_N];
    let (mut used, mut fixed) = (0u16, 0usize);
    for left in 0..n {
        let mut chosen = false;
        for right in 0..=n {
            let matched = right < n;
            if matched && (adj[left] & (1u16 << right) == 0 || used & (1u16 << right) != 0) { continue; }
            let next_used = if matched { used | (1u16 << right) } else { used };
            if fixed + matched as usize + maximum_matching(&adj, n, left + 1, next_used) == maximum {
                successor[left] = right; used = next_used; fixed += matched as usize;
                chosen = true; break;
            }
        }
        if !chosen { return -1; }
    }
    let mut result = ((n - maximum) as u64) << 40;
    for v in 0..n { result |= (successor[v] as u64) << (4 * v); }
    result as i64
}
