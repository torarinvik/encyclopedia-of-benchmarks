const MAX_N: usize = 32;
const MAX_INPUT_VALUES: usize = 5 * MAX_N - 3;
const MOD: i64 = 998_244_353;

fn find_root(parent: &mut [usize; MAX_N], mut item: usize) -> usize {
    while parent[item] != item {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    item
}

fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (8 * byte)) as u8); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tree_path_composite_sum(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let n_value = words[0];
    if n_value < 1 || n_value > MAX_N as i64 { return -1; }
    let n = n_value as usize;
    if length != 1 + n + 4 * (n - 1) { return -1; }

    let mut value = [0i64; MAX_N];
    for vertex in 0..n {
        value[vertex] = words[1 + vertex];
        if !(0..MOD).contains(&value[vertex]) { return -1; }
    }
    let mut adjacent = [[false; MAX_N]; MAX_N];
    let mut multiplier = [[0i64; MAX_N]; MAX_N];
    let mut addend = [[0i64; MAX_N]; MAX_N];
    let mut dsu_parent = [0usize; MAX_N];
    let mut dsu_size = [0usize; MAX_N];
    for vertex in 0..n { dsu_parent[vertex] = vertex; dsu_size[vertex] = 1; }
    let mut offset = 1 + n;
    for _ in 0..n - 1 {
        let (u_raw, v_raw, b, c) = (words[offset], words[offset + 1], words[offset + 2], words[offset + 3]);
        offset += 4;
        if u_raw < 0 || u_raw >= n_value || v_raw < 0 || v_raw >= n_value
            || u_raw == v_raw || b < 1 || b >= MOD || c < 0 || c >= MOD { return -1; }
        let (u, v) = (u_raw as usize, v_raw as usize);
        let (mut ru, mut rv) = (find_root(&mut dsu_parent, u), find_root(&mut dsu_parent, v));
        if ru == rv { return -1; }
        if dsu_size[ru] < dsu_size[rv] { std::mem::swap(&mut ru, &mut rv); }
        dsu_parent[rv] = ru;
        dsu_size[ru] += dsu_size[rv];
        adjacent[u][v] = true; adjacent[v][u] = true;
        multiplier[u][v] = b; multiplier[v][u] = b;
        addend[u][v] = c; addend[v][u] = c;
    }

    let mut order = [0usize; MAX_N];
    let mut stack = [0usize; MAX_N];
    let mut parent = [-2i64; MAX_N];
    parent[0] = -1;
    let (mut top, mut order_count) = (1usize, 0usize);
    stack[0] = 0;
    while top > 0 {
        top -= 1;
        let u = stack[top];
        order[order_count] = u; order_count += 1;
        for v in 0..n {
            if adjacent[u][v] && v as i64 != parent[u] {
                parent[v] = u as i64;
                stack[top] = v; top += 1;
            }
        }
    }

    let mut down_sum = [0i64; MAX_N]; let mut up_sum = [0i64; MAX_N];
    let mut down_count = [0usize; MAX_N]; let mut up_count = [0usize; MAX_N];
    let mut answer = [0i64; MAX_N];
    for pos in (0..order_count).rev() {
        let u = order[pos]; down_sum[u] = value[u]; down_count[u] = 1;
        for v in 0..n {
            if adjacent[u][v] && parent[v] == u as i64 {
                let contribution = (multiplier[u][v] * down_sum[v]
                    + addend[u][v] * down_count[v] as i64) % MOD;
                down_sum[u] = (down_sum[u] + contribution) % MOD;
                down_count[u] += down_count[v];
            }
        }
    }
    for pos in 0..order_count {
        let u = order[pos]; let mut total_sum = value[u]; let mut total_count = 1usize;
        if parent[u] >= 0 { total_sum = (total_sum + up_sum[u]) % MOD; total_count += up_count[u]; }
        for v in 0..n {
            if adjacent[u][v] && parent[v] == u as i64 {
                total_sum = (total_sum + multiplier[u][v] * down_sum[v]
                    + addend[u][v] * down_count[v] as i64) % MOD;
                total_count += down_count[v];
            }
        }
        answer[u] = total_sum;
        for v in 0..n {
            if adjacent[u][v] && parent[v] == u as i64 {
                let contribution = (multiplier[u][v] * down_sum[v]
                    + addend[u][v] * down_count[v] as i64) % MOD;
                let outside_sum = (total_sum - contribution + MOD) % MOD;
                let outside_count = total_count - down_count[v];
                up_sum[v] = (multiplier[u][v] * outside_sum
                    + addend[u][v] * outside_count as i64) % MOD;
                up_count[v] = outside_count;
            }
        }
    }
    let required = 8 * n;
    if output.is_null() || capacity < required { return -2; }
    for vertex in 0..n { store_le(output, 8 * vertex, answer[vertex]); }
    required as i64
}
