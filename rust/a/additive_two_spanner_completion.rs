const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_INPUT: usize = 59;
const INF: usize = 9;

unsafe fn put(output: *mut u8, at: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(at + byte) = (bits >> (8 * byte)) as u8; }
}

fn distances(n: usize, m: usize, u: &[usize; MAX_M], v: &[usize; MAX_M],
             selected: &[bool; MAX_M], only_selected: bool) -> [[usize; MAX_N]; MAX_N] {
    let mut d = [[INF; MAX_N]; MAX_N];
    for a in 0..n { d[a][a] = 0; }
    for edge in 0..m {
        if only_selected && !selected[edge] { continue; }
        d[u[edge]][v[edge]] = 1; d[v[edge]][u[edge]] = 1;
    }
    for via in 0..n {
        for left in 0..n {
            for right in 0..n {
                let candidate = d[left][via] + d[via][right];
                if candidate < d[left][right] { d[left][right] = candidate; }
            }
        }
    }
    d
}

#[no_mangle]
pub unsafe extern "C" fn additive_two_spanner_completion(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(1..=8).contains(&n64) || !(0..=28).contains(&m64)
        || length != 2 + 2 * m64 as usize { return -1; }
    let n = n64 as usize; let m = m64 as usize;
    let mut u = [0usize; MAX_M]; let mut v = [0usize; MAX_M];
    for edge in 0..m {
        let a = *input.add(2 + 2 * edge); let b = *input.add(3 + 2 * edge);
        if a < 0 || a >= b || b >= n64 { return -1; }
        u[edge] = a as usize; v[edge] = b as usize;
        for prior in 0..edge {
            if u[prior] == u[edge] && v[prior] == v[edge] { return -1; }
        }
    }
    let mut selected = [false; MAX_M];
    let original = distances(n, m, &u, &v, &selected, false);
    for round in 0..=m {
        let current = distances(n, m, &u, &v, &selected, true);
        let mut pair = None;
        'pairs: for a in 0..n {
            for b in a + 1..n {
                if original[a][b] < INF && current[a][b] > original[a][b] + 2 {
                    pair = Some((a, b)); break 'pairs;
                }
            }
        }
        let Some((source, target)) = pair else { break; };
        if round == m { return -1; }
        let mut vertex = source;
        while vertex != target {
            let mut next = n;
            for neighbor in 0..n {
                if neighbor == vertex || original[neighbor][target] + 1 != original[vertex][target] { continue; }
                for edge in 0..m {
                    if (u[edge] == vertex && v[edge] == neighbor)
                        || (v[edge] == vertex && u[edge] == neighbor) {
                        next = neighbor; selected[edge] = true; break;
                    }
                }
                if next != n { break; }
            }
            if next == n { return -1; }
            vertex = next;
        }
    }
    let count = (0..m).filter(|&edge| selected[edge]).count();
    let bytes = 8 * (1 + 2 * count);
    if output.is_null() || capacity < bytes { return -2; }
    put(output, 0, count as i64);
    let mut slot = 0;
    for edge in 0..m {
        if !selected[edge] { continue; }
        put(output, 8 * (1 + 2 * slot), u[edge] as i64);
        put(output, 8 * (2 + 2 * slot), v[edge] as i64);
        slot += 1;
    }
    bytes as i64
}
