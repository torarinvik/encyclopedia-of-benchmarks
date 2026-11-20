const MAX_N: usize = 8;
const MAX_EDGES: usize = 28;
const WALK_LIMIT: usize = 64;
const MAX_INPUT: usize = 4 + 2 * MAX_EDGES + WALK_LIMIT * (MAX_N - 1);

fn write_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (index, byte) in bytes.iter().enumerate() {
        unsafe { output.add(offset + index).write(*byte); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn wilson_uniform_spanning_tree(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(4..=MAX_INPUT + 1).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    let m_raw = values[1];
    let root_raw = values[2];
    if !(1..=MAX_N as i64).contains(&n_raw) || !(0..=MAX_EDGES as i64).contains(&m_raw) { return -1; }
    let n = n_raw as usize;
    let m = m_raw as usize;
    if root_raw < 0 || root_raw >= n_raw { return -1; }
    let root = root_raw as usize;
    let q_at = 3 + 2 * m;
    if length <= q_at { return -1; }
    let q_raw = values[q_at];
    if q_raw < 0 || q_raw > (WALK_LIMIT * (n - 1)) as i64 { return -1; }
    let q = q_raw as usize;
    if length != q_at + 1 + q { return -1; }

    let mut neighbors = [[0usize; MAX_N - 1]; MAX_N];
    let mut degree = [0usize; MAX_N];
    let (mut previous_u, mut previous_v) = (-1i64, -1i64);
    for edge in 0..m {
        let u_raw = values[3 + 2 * edge];
        let v_raw = values[4 + 2 * edge];
        if u_raw < 0 || u_raw >= v_raw || v_raw >= n_raw { return -1; }
        if edge > 0 && (u_raw < previous_u || (u_raw == previous_u && v_raw <= previous_v)) { return -1; }
        previous_u = u_raw; previous_v = v_raw;
        let (u, v) = (u_raw as usize, v_raw as usize);
        neighbors[u][degree[u]] = v; degree[u] += 1;
        neighbors[v][degree[v]] = u; degree[v] += 1;
    }
    if values[q_at + 1..].iter().any(|&draw| draw < 0 || draw > (MAX_N - 2) as i64) { return -1; }

    let mut seen = [false; MAX_N];
    let mut queue = [0usize; MAX_N];
    let (mut head, mut tail) = (0usize, 0usize);
    seen[root] = true; queue[tail] = root; tail += 1;
    while head < tail {
        let at = queue[head]; head += 1;
        for &to in &neighbors[at][..degree[at]] {
            if !seen[to] { seen[to] = true; queue[tail] = to; tail += 1; }
        }
    }
    if (0..n).any(|vertex| !seen[vertex]) { return -1; }

    let mut in_tree = [false; MAX_N];
    let mut successor = [-1i64; MAX_N];
    in_tree[root] = true;
    let mut cursor = 0usize;
    for start in 0..n {
        if in_tree[start] { continue; }
        let (mut current, mut steps) = (start, 0usize);
        while !in_tree[current] {
            if steps >= WALK_LIMIT || cursor >= q { return -1; }
            let choice = values[q_at + 1 + cursor] as usize;
            if choice >= degree[current] { return -1; }
            successor[current] = neighbors[current][choice] as i64;
            current = successor[current] as usize;
            cursor += 1; steps += 1;
        }
        current = start;
        while !in_tree[current] { in_tree[current] = true; current = successor[current] as usize; }
    }
    if cursor != q { return -1; }

    let required = 16 * (n - 1);
    if (required > 0 && output.is_null()) || capacity < required { return -2; }
    let mut offset = 0usize;
    for child in 0..n {
        if child == root { continue; }
        write_i64_le(output, offset, child as i64); offset += 8;
        write_i64_le(output, offset, successor[child]); offset += 8;
    }
    required as i64
}
