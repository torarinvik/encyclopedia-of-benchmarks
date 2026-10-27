/// Bounded Extended-GS for concave multi-unit stable allocations.
const MAX_INPUT: usize = 19;
const MAX_OUTPUT_BYTES: usize = 104;
const INF: i64 = 255;

fn utility(first: i64, second: i64, count: i64) -> i64 {
    if count == 0 { 0 } else if count == 1 { first } else { first + second }
}

fn choose_men(men: usize, women: usize, quota: i64, edges: usize,
              mf: &[i64; 4], ms: &[i64; 4], lower: &[i64; 4], upper: &[i64; 4],
              answer: &mut [i64; 4]) {
    let mut best_value = -1;
    let codes = 3usize.pow(edges as u32);
    for code in 0..codes {
        let mut candidate = [0i64; 4];
        let mut remainder = code;
        for edge in (0..edges).rev() { candidate[edge] = (remainder % 3) as i64; remainder /= 3; }
        let mut feasible = true;
        for edge in 0..edges { if candidate[edge] < lower[edge] || candidate[edge] > upper[edge] { feasible = false; } }
        for man in 0..men {
            let mut total = 0;
            for woman in 0..women { total += candidate[man * women + woman]; }
            if total > quota { feasible = false; }
        }
        if !feasible { continue; }
        let mut value = 0;
        for edge in 0..edges { value += utility(mf[edge], ms[edge], candidate[edge]); }
        if value > best_value { best_value = value; for edge in 0..edges { answer[edge] = candidate[edge]; } }
    }
}

fn choose_women(men: usize, women: usize, quota: i64, edges: usize,
                wf: &[i64; 4], ws: &[i64; 4], upper: &[i64; 4], answer: &mut [i64; 4]) {
    let mut best_value = -1;
    let codes = 3usize.pow(edges as u32);
    for code in 0..codes {
        let mut candidate = [0i64; 4];
        let mut remainder = code;
        for edge in (0..edges).rev() { candidate[edge] = (remainder % 3) as i64; remainder /= 3; }
        let mut feasible = true;
        for edge in 0..edges { if candidate[edge] > upper[edge] { feasible = false; } }
        for woman in 0..women {
            let mut total = 0;
            for man in 0..men { total += candidate[man * women + woman]; }
            if total > quota { feasible = false; }
        }
        if !feasible { continue; }
        let mut value = 0;
        for edge in 0..edges { value += utility(wf[edge], ws[edge], candidate[edge]); }
        if value > best_value { best_value = value; for edge in 0..edges { answer[edge] = candidate[edge]; } }
    }
}

fn put_i64(output: &mut [u8; MAX_OUTPUT_BYTES], offset: usize, value: i64) {
    for byte in 0..8 { output[offset + byte] = ((value as u64 >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn extended_gs_general_stable_allocation(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=2).contains(&values[0]) || !(1..=2).contains(&values[1]) || !(1..=2).contains(&values[2]) { return -1; }
    let men = values[0] as usize;
    let women = values[1] as usize;
    let quota = values[2];
    let edges = men * women;
    if length != 3 + 4 * edges { return -1; }
    let mut mf = [0i64; 4]; let mut ms = [0i64; 4];
    let mut wf = [0i64; 4]; let mut ws = [0i64; 4];
    for edge in 0..edges {
        mf[edge] = values[3 + 4 * edge]; ms[edge] = values[4 + 4 * edge];
        wf[edge] = values[5 + 4 * edge]; ws[edge] = values[6 + 4 * edge];
        if mf[edge] < 0 || mf[edge] > 8 || ms[edge] < 0 || ms[edge] > mf[edge]
            || wf[edge] < 0 || wf[edge] > 8 || ws[edge] < 0 || ws[edge] > wf[edge] { return -1; }
    }
    let mut x_w = [0i64; 4]; let mut z_m = [INF; 4]; let mut z_w = [0i64; 4];
    let mut x_m = [0i64; 4]; let mut next_w = [0i64; 4];
    let mut converged = false;
    for _ in 0..3 * edges + 2 {
        choose_men(men, women, quota, edges, &mf, &ms, &x_w, &z_m, &mut x_m);
        choose_women(men, women, quota, edges, &wf, &ws, &x_m, &mut next_w);
        converged = true;
        for edge in 0..edges { if x_m[edge] != next_w[edge] { converged = false; } }
        if converged { break; }
        for edge in 0..edges {
            if x_m[edge] > next_w[edge] { z_m[edge] = next_w[edge]; z_w[edge] = INF; }
            x_w[edge] = next_w[edge];
        }
    }
    if !converged { return -1; }
    let output_values = 1 + 3 * edges;
    let output_bytes = 8 * output_values;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    put_i64(&mut staged, 0, edges as i64);
    for edge in 0..edges {
        put_i64(&mut staged, 8 * (1 + edge), x_m[edge]);
        put_i64(&mut staged, 8 * (1 + edges + edge), z_m[edge]);
        put_i64(&mut staged, 8 * (1 + 2 * edges + edge), z_w[edge].max(x_m[edge]));
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_bytes);
    output_bytes as i64
}
