const MAX_OBSERVATIONS: usize = 128;
const MAX_GROUPS: usize = 8;
const INVALID_RESULT: f64 = -1.0e300;

fn safe_denominator(value: f64) -> f64 {
    if value.abs() >= 1.0e-300 { value } else if value < 0.0 { -1.0e-300 } else { 1.0e-300 }
}

fn log_gamma_lanczos(value: f64) -> f64 {
    let z = value - 1.0;
    let mut sum = 0.99999999999980993;
    sum += 676.5203681218851 / (z + 1.0);
    sum -= 1259.1392167224028 / (z + 2.0);
    sum += 771.32342877765313 / (z + 3.0);
    sum -= 176.61502916214059 / (z + 4.0);
    sum += 12.507343278686905 / (z + 5.0);
    sum -= 0.13857109526572012 / (z + 6.0);
    sum += 9.9843695780195716e-6 / (z + 7.0);
    sum += 1.5056327351493116e-7 / (z + 8.0);
    let t = z + 7.5;
    0.91893853320467274178 + (z + 0.5) * t.ln() - t + sum.ln()
}

fn beta_fraction(a: f64, b: f64, x: f64) -> f64 {
    let qab = a + b;
    let qap = a + 1.0;
    let qam = a - 1.0;
    let mut c = 1.0;
    let mut d = safe_denominator(1.0 - qab * x / qap);
    d = 1.0 / d;
    let mut result = d;
    for m in 1..=200 {
        let md = m as f64;
        let m2 = 2.0 * md;
        let mut coefficient = md * (b - md) * x / ((qam + m2) * (a + m2));
        d = safe_denominator(1.0 + coefficient * d);
        c = safe_denominator(1.0 + coefficient / c);
        d = 1.0 / d;
        result *= d * c;
        coefficient = -(a + md) * (qab + md) * x / ((a + m2) * (qap + m2));
        d = safe_denominator(1.0 + coefficient * d);
        c = safe_denominator(1.0 + coefficient / c);
        d = 1.0 / d;
        let change = d * c;
        result *= change;
        if (change - 1.0).abs() <= 3.0e-14 { break; }
    }
    result
}

fn regularized_beta(x: f64, a: f64, b: f64) -> f64 {
    if x <= 0.0 { return 0.0; }
    if x >= 1.0 { return 1.0; }
    let front = (a * x.ln() + b * (1.0 - x).ln() +
                 log_gamma_lanczos(a + b) - log_gamma_lanczos(a) - log_gamma_lanczos(b)).exp();
    if x < (a + 1.0) / (a + b + 2.0) { return front * beta_fraction(a, b, x) / a; }
    1.0 - front * beta_fraction(b, a, 1.0 - x) / b
}

#[no_mangle]
pub unsafe extern "C" fn anova_oneway(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 3 { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let statistic = values[0];
    let observation_count = values[1];
    let group_count = values[2];
    if !(0..=7).contains(&statistic) || observation_count <= group_count || !(3..=MAX_OBSERVATIONS as i64).contains(&observation_count)
        || !(2..=MAX_GROUPS as i64).contains(&group_count) || length != 3 + 2 * observation_count as usize { return INVALID_RESULT; }

    let mut group_sums = [0.0; MAX_GROUPS];
    let mut group_means = [0.0; MAX_GROUPS];
    let mut group_sizes = [0i64; MAX_GROUPS];
    let mut labels = [0i64; MAX_OBSERVATIONS];
    let mut total = 0.0;
    for i in 0..observation_count as usize {
        let value = values[3 + i];
        let group = values[3 + observation_count as usize + i];
        if !(-1_000_000..=1_000_000).contains(&value) || group < 0 || group >= group_count { return INVALID_RESULT; }
        labels[i] = group;
        group_sums[group as usize] += value as f64;
        group_sizes[group as usize] += 1;
        total += value as f64;
    }
    for group in 0..group_count as usize {
        if group_sizes[group] == 0 { return INVALID_RESULT; }
        group_means[group] = group_sums[group] / group_sizes[group] as f64;
    }
    let grand_mean = total / observation_count as f64;
    let mut ss_between = 0.0;
    for group in 0..group_count as usize {
        let difference = group_means[group] - grand_mean;
        ss_between += group_sizes[group] as f64 * difference * difference;
    }
    let mut ss_within = 0.0;
    for group in 0..group_count as usize {
        for i in 0..observation_count as usize {
            if labels[i] == group as i64 {
                let difference = values[3 + i] as f64 - group_means[group];
                ss_within += difference * difference;
            }
        }
    }
    if ss_within <= 0.0 { return INVALID_RESULT; }
    let df_between = (group_count - 1) as f64;
    let df_within = (observation_count - group_count) as f64;
    let ms_between = ss_between / df_between;
    let ms_within = ss_within / df_within;
    let f_statistic = ms_between / ms_within;
    let beta_x = df_within / (df_within + df_between * f_statistic);
    let p_value = regularized_beta(beta_x, df_within / 2.0, df_between / 2.0);
    let outputs = [df_between, df_within, ss_between, ss_within, ms_between, ms_within, f_statistic, p_value];
    outputs[statistic as usize]
}
