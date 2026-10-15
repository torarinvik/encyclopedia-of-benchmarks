const INVALID_RESULT: f64 = -1.0e300;

fn assign_ranks(data: &[i64], ranks: &mut [f64; 3]) {
    let n = data.len();
    let mut order = [0usize; 3];
    for i in 0..n { order[i] = i; }
    for i in 1..n {
        let key = order[i];
        let mut j = i;
        while j > 0 && data[order[j - 1]] > data[key] {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = key;
    }
    let mut i = 0;
    while i < n {
        let mut j = i;
        while j < n - 1 && data[order[j + 1]] == data[order[i]] { j += 1; }
        let rank = (i as f64 + j as f64) / 2.0 + 1.0;
        for k in i..=j { ranks[order[k]] = rank; }
        i = j + 1;
    }
}

fn round_tenth_ties_even(value: f64) -> f64 {
    let scaled = value * 10.0;
    let lower = scaled.floor();
    let fraction = scaled - lower;
    let mut rounded = lower;
    if fraction > 0.5 || (fraction == 0.5 && (lower as i64) % 2 != 0) { rounded = lower + 1.0; }
    rounded / 10.0
}

#[no_mangle]
pub extern "C" fn spearman_rank_correlation_coefficient(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 5 { return INVALID_RESULT; }
    let n_value = unsafe { *values };
    if !(2..=3).contains(&n_value) || length != 1 + 2 * n_value as usize { return INVALID_RESULT; }
    let n = n_value as usize;
    let x = unsafe { std::slice::from_raw_parts(values.add(1), n) };
    let y = unsafe { std::slice::from_raw_parts(values.add(1 + n), n) };
    if x.iter().chain(y).any(|value| !(-1000..=1000).contains(value)) { return INVALID_RESULT; }
    let mut rank_x = [0.0; 3];
    let mut rank_y = [0.0; 3];
    assign_ranks(x, &mut rank_x);
    assign_ranks(y, &mut rank_y);
    let mut d_squared = 0.0;
    for i in 0..n {
        let difference = rank_x[i] - rank_y[i];
        d_squared += difference * difference;
    }
    let nf = n as f64;
    let rho = 1.0 - (6.0 * d_squared) / (nf * (nf * nf - 1.0));
    round_tenth_ties_even(rho)
}
