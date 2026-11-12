const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 16;
const MAX_INPUT_LENGTH: usize = 51;
const OUTPUT_BYTES: usize = 16;

#[derive(Clone, Copy, Default)]
struct Edge { from: usize, to: usize, weight: i64 }

fn all_reachable(n: usize, adjacent: &[[bool; MAX_VERTICES]; MAX_VERTICES], reverse: bool) -> bool {
    let mut seen = [false; MAX_VERTICES];
    let mut queue = [0_usize; MAX_VERTICES];
    let (mut head, mut tail) = (0, 0);
    seen[0] = true;
    queue[tail] = 0;
    tail += 1;
    while head < tail {
        let u = queue[head];
        head += 1;
        for v in 0..n {
            let has_edge = if reverse { adjacent[v][u] } else { adjacent[u][v] };
            if has_edge && !seen[v] {
                seen[v] = true;
                queue[tail] = v;
                tail += 1;
            }
        }
    }
    (0..n).all(|v| seen[v])
}

fn ratio_less(a_num: i64, a_den: i64, b_num: i64, b_den: i64) -> bool {
    a_num * b_den < b_num * a_den
}

fn gcd_positive(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { let remainder = a % b; a = b; b = remainder; }
    a
}

fn store_i64_le(output: &mut [u8; OUTPUT_BYTES], offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    output[offset..offset + 8].copy_from_slice(&bytes);
}

#[no_mangle]
pub unsafe extern "C" fn minimum_mean_cycle_karp(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_VERTICES as i64
        || values[1] < 1 || values[1] > MAX_EDGES as i64 { return -1; }
    let n = values[0] as usize;
    let edge_count = values[1] as usize;
    if edge_count > n * n || length != 2 + 3 * edge_count { return -1; }

    let mut edges = [Edge::default(); MAX_EDGES];
    let mut adjacent = [[false; MAX_VERTICES]; MAX_VERTICES];
    for i in 0..edge_count {
        let from_value = values[2 + 3 * i];
        let to_value = values[3 + 3 * i];
        let weight = values[4 + 3 * i];
        if from_value < 0 || from_value >= n as i64 || to_value < 0 || to_value >= n as i64
            || !(-1000..=1000).contains(&weight) { return -1; }
        let from = from_value as usize;
        let to = to_value as usize;
        if adjacent[from][to] { return -1; }
        adjacent[from][to] = true;
        edges[i] = Edge { from, to, weight };
    }
    if !all_reachable(n, &adjacent, false) || !all_reachable(n, &adjacent, true) { return -1; }
    if output.is_null() || capacity < OUTPUT_BYTES { return -2; }

    let mut cost = [[0_i64; MAX_VERTICES]; MAX_VERTICES + 1];
    let mut reachable = [[false; MAX_VERTICES]; MAX_VERTICES + 1];
    reachable[0][0] = true;
    for path_length in 1..=n {
        for edge in edges.iter().take(edge_count) {
            if !reachable[path_length - 1][edge.from] { continue; }
            let candidate = cost[path_length - 1][edge.from] + edge.weight;
            if !reachable[path_length][edge.to] || candidate < cost[path_length][edge.to] {
                reachable[path_length][edge.to] = true;
                cost[path_length][edge.to] = candidate;
            }
        }
    }

    let mut have_answer = false;
    let (mut answer_num, mut answer_den) = (0_i64, 1_i64);
    for v in 0..n {
        if !reachable[n][v] { continue; }
        let mut have_local = false;
        let (mut local_num, mut local_den) = (0_i64, 1_i64);
        for k in 0..n {
            if !reachable[k][v] { continue; }
            let numerator = cost[n][v] - cost[k][v];
            let denominator = (n - k) as i64;
            if !have_local || ratio_less(local_num, local_den, numerator, denominator) {
                local_num = numerator;
                local_den = denominator;
                have_local = true;
            }
        }
        if have_local && (!have_answer || ratio_less(local_num, local_den, answer_num, answer_den)) {
            answer_num = local_num;
            answer_den = local_den;
            have_answer = true;
        }
    }
    if !have_answer { return -1; }
    let divisor = gcd_positive(answer_num.abs(), answer_den);
    answer_num /= divisor;
    answer_den /= divisor;
    let mut staged = [0_u8; OUTPUT_BYTES];
    store_i64_le(&mut staged, 0, answer_num);
    store_i64_le(&mut staged, 8, answer_den);
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, OUTPUT_BYTES);
    OUTPUT_BYTES as i64
}
