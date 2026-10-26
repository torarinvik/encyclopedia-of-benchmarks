#[no_mangle]
pub unsafe extern "C" fn gapbs_pagerank_pull_gs(input: *const i64, length: usize) -> i64 {
    const MAX_N: usize = 8;
    if input.is_null() || !(6..=2 + MAX_N * MAX_N).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    let iterations_value = values[1];
    if !(2..=MAX_N as i64).contains(&n_value) || !(0..=20).contains(&iterations_value) { return -1; }
    let n = n_value as usize;
    let iterations = iterations_value as usize;
    if length != 2 + n * n { return -1; }
    let mut matrix = [0u8; MAX_N * MAX_N];
    let mut outdegree = [0usize; MAX_N];
    for row in 0..n {
        for column in 0..n {
            let value = values[2 + row * n + column];
            if (value != 0 && value != 1) || (row == column && value != 0) { return -1; }
            matrix[row * n + column] = value as u8;
            outdegree[row] += value as usize;
        }
        if outdegree[row] == 0 { return -1; }
    }
    let damping: f32 = 0.85;
    let init_score = 1.0f32 / n as f32;
    let base_score = (1.0f32 - damping) / n as f32;
    let mut scores = [0.0f32; MAX_N];
    let mut outgoing = [0.0f32; MAX_N];
    for node in 0..n {
        scores[node] = init_score;
        outgoing[node] = init_score / outdegree[node] as f32;
    }
    for _ in 0..iterations {
        for target in 0..n {
            let mut incoming = 0.0f32;
            for source in 0..n {
                if matrix[source * n + target] != 0 { incoming += outgoing[source]; }
            }
            scores[target] = base_score + damping * incoming;
            outgoing[target] = scores[target] / outdegree[target] as f32;
        }
    }
    let mut weighted = 0.0f64;
    for node in 0..n { weighted += (node + 1) as f64 * scores[node] as f64; }
    (weighted * 100.0 + 0.5) as i64
}
