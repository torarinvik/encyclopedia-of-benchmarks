const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 16;
const MAX_INPUT_LENGTH: usize = 51;
const OUTPUT_BYTES: usize = 16;

#[derive(Clone, Copy, Default)]
struct Edge {
    from: usize,
    to: usize,
    weight: i64,
}

fn store_i64_le(output: &mut [u8; OUTPUT_BYTES], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

fn gcd_positive(mut a: i64, mut b: i64) -> i64 {
    while b != 0 {
        let remainder = a % b;
        a = b;
        b = remainder;
    }
    a
}

fn compare_ratio(a_num: i64, a_den: i64, b_num: i64, b_den: i64) -> i32 {
    let left = a_num * b_den;
    let right = b_num * a_den;
    if left < right { -1 } else if left > right { 1 } else { 0 }
}

fn all_reachable(n: usize, adjacent: &[[bool; MAX_VERTICES]; MAX_VERTICES], reverse: bool) -> bool {
    let mut seen = [false; MAX_VERTICES];
    let mut queue = [0usize; MAX_VERTICES];
    let (mut head, mut tail) = (0usize, 1usize);
    seen[0] = true;
    queue[0] = 0;
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

fn compare_appraisal(
    a_edge: usize,
    b_edge: usize,
    edges: &[Edge; MAX_EDGES],
    value_num: &[i64; MAX_VERTICES],
    value_den: &[i64; MAX_VERTICES],
    bias_num: &[i64; MAX_VERTICES],
) -> i32 {
    let a = edges[a_edge];
    let b = edges[b_edge];
    let comparison = compare_ratio(value_num[a.to], value_den[a.to], value_num[b.to], value_den[b.to]);
    if comparison != 0 { return comparison; }
    let a_bias = a.weight * value_den[a.to] - value_num[a.to] + bias_num[a.to];
    let b_bias = b.weight * value_den[b.to] - value_num[b.to] + bias_num[b.to];
    compare_ratio(a_bias, value_den[a.to], b_bias, value_den[b.to])
}

fn evaluate_policy(
    n: usize,
    edges: &[Edge; MAX_EDGES],
    policy: &[usize; MAX_VERTICES],
    value_num: &mut [i64; MAX_VERTICES],
    value_den: &mut [i64; MAX_VERTICES],
    bias_num: &mut [i64; MAX_VERTICES],
) {
    let mut assigned = [false; MAX_VERTICES];
    for start in 0..n {
        if assigned[start] { continue; }
        let mut local_position = [-1i32; MAX_VERTICES];
        let mut path = [0usize; MAX_VERTICES];
        let mut path_length = 0usize;
        let mut vertex = start;
        while !assigned[vertex] && local_position[vertex] < 0 {
            local_position[vertex] = path_length as i32;
            path[path_length] = vertex;
            path_length += 1;
            vertex = edges[policy[vertex]].to;
        }

        let mut prefix_length = path_length;
        if !assigned[vertex] {
            let cycle_start = local_position[vertex] as usize;
            let cycle_length = path_length - cycle_start;
            let mut cycle_weight = 0i64;
            let mut head_position = cycle_start;
            for index in cycle_start..path_length {
                let member = path[index];
                cycle_weight += edges[policy[member]].weight;
                if path[index] < path[head_position] { head_position = index; }
            }
            let divisor = gcd_positive(cycle_weight.abs(), cycle_length as i64);
            let mean_num = cycle_weight / divisor;
            let mean_den = cycle_length as i64 / divisor;
            let head = path[head_position];
            for index in cycle_start..path_length {
                let member = path[index];
                value_num[member] = mean_num;
                value_den[member] = mean_den;
                assigned[member] = true;
            }

            bias_num[head] = 0;
            let mut current_position = head_position;
            loop {
                let previous_position = if current_position == cycle_start { path_length - 1 } else { current_position - 1 };
                let previous = path[previous_position];
                if previous == head { break; }
                bias_num[previous] = edges[policy[previous]].weight * mean_den - mean_num
                    + bias_num[path[current_position]];
                current_position = previous_position;
            }
            prefix_length = cycle_start;
        }

        let mut prefix_position = prefix_length;
        while prefix_position > 0 {
            prefix_position -= 1;
            let u = path[prefix_position];
            let successor = edges[policy[u]].to;
            value_num[u] = value_num[successor];
            value_den[u] = value_den[successor];
            bias_num[u] = edges[policy[u]].weight * value_den[successor]
                - value_num[successor] + bias_num[successor];
            assigned[u] = true;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn minimum_mean_cycle_howard(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if values[0] < 1 || values[0] > MAX_VERTICES as i64
        || values[1] < 1 || values[1] > MAX_EDGES as i64 { return -1; }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if m > n * n || input_length != 2 + 3 * m { return -1; }

    let mut edges = [Edge::default(); MAX_EDGES];
    let mut adjacent = [[false; MAX_VERTICES]; MAX_VERTICES];
    let mut outgoing = [[0usize; MAX_EDGES]; MAX_VERTICES];
    let mut degree = [0usize; MAX_VERTICES];
    let mut policy = [0usize; MAX_VERTICES];
    for edge_index in 0..m {
        let from_value = values[2 + 3 * edge_index];
        let to_value = values[3 + 3 * edge_index];
        let weight = values[4 + 3 * edge_index];
        if from_value < 0 || from_value >= n as i64 || to_value < 0 || to_value >= n as i64
            || !(-1000..=1000).contains(&weight) { return -1; }
        let from = from_value as usize;
        let to = to_value as usize;
        if adjacent[from][to] { return -1; }
        adjacent[from][to] = true;
        edges[edge_index] = Edge { from, to, weight };
        outgoing[from][degree[from]] = edge_index;
        degree[from] += 1;
        if degree[from] == 1 { policy[from] = edge_index; }
    }
    if !all_reachable(n, &adjacent, false) || !all_reachable(n, &adjacent, true) { return -1; }
    if output.is_null() || output_capacity < OUTPUT_BYTES { return -2; }

    let mut policy_limit = 1usize;
    for vertex in 0..n { policy_limit *= degree[vertex]; }
    let mut value_num = [0i64; MAX_VERTICES];
    let mut value_den = [1i64; MAX_VERTICES];
    let mut bias_num = [0i64; MAX_VERTICES];
    let mut converged = false;
    for _ in 0..policy_limit {
        evaluate_policy(n, &edges, &policy, &mut value_num, &mut value_den, &mut bias_num);
        let mut improved = policy;
        let mut changed = false;
        for vertex in 0..n {
            let mut best = policy[vertex];
            for index in 0..degree[vertex] {
                let candidate = outgoing[vertex][index];
                if compare_appraisal(candidate, best, &edges, &value_num, &value_den, &bias_num) < 0 {
                    best = candidate;
                }
            }
            improved[vertex] = best;
            if best != policy[vertex] { changed = true; }
        }
        if !changed {
            converged = true;
            break;
        }
        policy = improved;
    }
    if !converged { return -1; }

    let mut best_vertex = 0usize;
    for vertex in 1..n {
        if compare_ratio(value_num[vertex], value_den[vertex], value_num[best_vertex], value_den[best_vertex]) < 0 {
            best_vertex = vertex;
        }
    }
    let mut answer_num = value_num[best_vertex];
    let mut answer_den = value_den[best_vertex];
    let divisor = gcd_positive(answer_num.abs(), answer_den);
    answer_num /= divisor;
    answer_den /= divisor;

    let mut staged = [0u8; OUTPUT_BYTES];
    store_i64_le(&mut staged, 0, answer_num);
    store_i64_le(&mut staged, 8, answer_den);
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, OUTPUT_BYTES);
    OUTPUT_BYTES as i64
}
