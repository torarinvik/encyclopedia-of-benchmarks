// Clean-room degree-oriented simple C4 counter; see package RIGHTS.md.
#[no_mangle]
pub unsafe extern "C" fn undirected_four_cycle_count_degree_order(
    input: *const i64,
    length: usize,
) -> i64 {
    const MAX_N: usize = 16;
    const MAX_M: usize = 64;
    if input.is_null() || length < 2 || length > 131 { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64) {
        return -1;
    }
    let n = n64 as usize;
    let m = m64 as usize;
    if length != 2 + 2 * m { return -1; }

    let mut neighbors = [[0usize; MAX_N]; MAX_N];
    let mut degree = [0usize; MAX_N];
    let mut previous_u = -1i64;
    let mut previous_v = -1i64;
    for edge in 0..m {
        let u64 = *input.add(2 + 2 * edge);
        let v64 = *input.add(3 + 2 * edge);
        if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || u64 >= v64 { return -1; }
        if edge != 0 && (u64 < previous_u || (u64 == previous_u && v64 <= previous_v)) {
            return -1;
        }
        previous_u = u64;
        previous_v = v64;
        let u = u64 as usize;
        let v = v64 as usize;
        neighbors[u][degree[u]] = v;
        degree[u] += 1;
        neighbors[v][degree[v]] = u;
        degree[v] += 1;
    }

    let mut order = [0usize; MAX_N];
    let mut rank = [0usize; MAX_N];
    for i in 0..n { order[i] = i; }
    for i in 1..n {
        let key = order[i];
        let mut j = i;
        while j > 0 {
            let prior = order[j - 1];
            if degree[prior] < degree[key] || (degree[prior] == degree[key] && prior < key) {
                break;
            }
            order[j] = prior;
            j -= 1;
        }
        order[j] = key;
    }
    for i in 0..n { rank[order[i]] = i; }

    let mut count = [0i64; MAX_N];
    let mut total = 0i64;
    for position in 0..n {
        let pivot = order[position];
        for bi in 0..degree[pivot] {
            let middle = neighbors[pivot][bi];
            if rank[middle] >= position { continue; }
            for ci in 0..degree[middle] {
                let opposite = neighbors[middle][ci];
                if rank[opposite] < position {
                    total += count[opposite];
                    count[opposite] += 1;
                }
            }
        }
        for vertex in 0..n { count[vertex] = 0; }
    }
    total
}
