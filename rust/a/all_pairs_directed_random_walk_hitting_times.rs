const MAX_N: usize = 8;
const MAX_INPUT_LENGTH: usize = 115;
const MOD: i64 = 1_000_000_007;

fn norm(value: i64) -> i64 {
    let remainder = value % MOD;
    if remainder < 0 { remainder + MOD } else { remainder }
}

fn power(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1_i64;
    base = norm(base);
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MOD; }
        base = base * base % MOD;
        exponent >>= 1;
    }
    result
}

fn reaches_all(graph: &[[bool; MAX_N]; MAX_N], n: usize, reverse: bool) -> bool {
    let mut seen = [false; MAX_N];
    let mut queue = [0_usize; MAX_N];
    let (mut head, mut tail) = (0_usize, 0_usize);
    seen[0] = true;
    queue[tail] = 0;
    tail += 1;
    while head < tail {
        let from = queue[head];
        head += 1;
        for to in 0..n {
            let has_edge = if reverse { graph[to][from] } else { graph[from][to] };
            if has_edge && !seen[to] {
                seen[to] = true;
                queue[tail] = to;
                tail += 1;
            }
        }
    }
    tail == n
}

fn eliminate(matrix: &mut [[i64; 2 * MAX_N + 1]; MAX_N], size: usize,
              rhs_count: usize) -> bool {
    let width = size + rhs_count;
    for column in 0..size {
        let mut pivot = column;
        while pivot < size && norm(matrix[pivot][column]) == 0 { pivot += 1; }
        if pivot == size { return false; }
        matrix.swap(column, pivot);
        let inverse = power(matrix[column][column], MOD - 2);
        for j in 0..width { matrix[column][j] = matrix[column][j] * inverse % MOD; }
        for row in 0..size {
            if row == column { continue; }
            let factor = norm(matrix[row][column]);
            if factor == 0 { continue; }
            for j in 0..width {
                matrix[row][j] = norm(matrix[row][j] - factor * matrix[column][j] % MOD);
            }
        }
    }
    true
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    for (index, byte) in value.to_le_bytes().iter().enumerate() {
        unsafe { *output.add(offset + index) = *byte; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn all_pairs_directed_random_walk_hitting_times(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    let m_value = values[1];
    if !(3..=MAX_N as i64).contains(&n_value) { return -1; }
    if m_value < 0 || m_value > n_value * (n_value - 1) { return -1; }
    let n = n_value as usize;
    let m = m_value as usize;
    if length != 2 + 2 * m { return -1; }

    let mut graph = [[false; MAX_N]; MAX_N];
    let mut degree = [0_usize; MAX_N];
    for edge in 0..m {
        let u_value = values[2 + 2 * edge];
        let v_value = values[3 + 2 * edge];
        if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
            || u_value == v_value { return -1; }
        let u = u_value as usize;
        let v = v_value as usize;
        if graph[u][v] { return -1; }
        graph[u][v] = true;
        degree[u] += 1;
    }
    if degree[..n].contains(&0) || !reaches_all(&graph, n, false)
        || !reaches_all(&graph, n, true) { return -1; }
    let output_bytes = 8 * n * n;
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut stationary = [[0_i64; 2 * MAX_N + 1]; MAX_N];
    for destination in 0..n - 1 {
        for source in 0..n {
            let transition = if graph[source][destination] {
                power(degree[source] as i64, MOD - 2)
            } else { 0 };
            let identity = if source == destination { 1 } else { 0 };
            stationary[destination][source] = norm(transition - identity);
        }
    }
    for source in 0..n { stationary[n - 1][source] = 1; }
    stationary[n - 1][n] = 1;
    if !eliminate(&mut stationary, n, 1) { return -1; }
    let mut reciprocal = [0_i64; MAX_N];
    for vertex in 0..n {
        let pi = norm(stationary[vertex][n]);
        if pi == 0 { return -1; }
        reciprocal[vertex] = power(pi, MOD - 2);
    }

    let mut reduced = [[0_i64; 2 * MAX_N + 1]; MAX_N];
    for row in 0..n - 1 {
        for column in 0..n - 1 {
            let transition = if graph[row][column] {
                power(degree[row] as i64, MOD - 2)
            } else { 0 };
            let identity = if row == column { 1 } else { 0 };
            reduced[row][column] = norm(identity - transition);
        }
        for target in 0..n {
            let correction = if row == target { reciprocal[target] } else { 0 };
            reduced[row][n - 1 + target] = norm(1 - correction);
        }
    }
    if !eliminate(&mut reduced, n - 1, n) { return -1; }
    let mut y = [[0_i64; MAX_N]; MAX_N];
    for row in 0..n - 1 {
        for target in 0..n { y[row][target] = norm(reduced[row][n - 1 + target]); }
    }
    for source in 0..n {
        for target in 0..n {
            let answer = norm(y[source][target] - y[target][target]);
            unsafe { store_i64_le(output, 8 * (source * n + target), answer); }
        }
    }
    output_bytes as i64
}
