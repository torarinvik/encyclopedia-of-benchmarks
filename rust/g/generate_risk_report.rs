use std::f64::consts::PI;

const MAX_INPUT_LENGTH: usize = 69;

fn qnorm(confidence: f64) -> f64 {
    let q = confidence - 0.5;
    if q.abs() <= 0.425 {
        let r = 0.180625 - q * q;
        let mut numerator = 2509.0809287301226727;
        numerator = numerator * r + 33430.575583588128105;
        numerator = numerator * r + 67265.770927008700853;
        numerator = numerator * r + 45921.953931549871457;
        numerator = numerator * r + 13731.693765509461125;
        numerator = numerator * r + 1971.5909503065514427;
        numerator = numerator * r + 133.14166789178437745;
        numerator = numerator * r + 3.387132872796366608;
        let mut denominator = 5226.495278852854561;
        denominator = denominator * r + 28729.085735721942674;
        denominator = denominator * r + 39307.89580009271061;
        denominator = denominator * r + 21213.794301586595867;
        denominator = denominator * r + 5394.1960214247511077;
        denominator = denominator * r + 687.1870074920579083;
        denominator = denominator * r + 42.313330701600911252;
        denominator = denominator * r + 1.0;
        return q * (numerator / denominator);
    }
    let r = (-(1.0 - confidence).ln()).sqrt() - 1.6;
    let mut numerator = 7.7454501427834140764e-4;
    numerator = numerator * r + 0.0227238449892691845833;
    numerator = numerator * r + 0.24178072517745061177;
    numerator = numerator * r + 1.27045825245236838258;
    numerator = numerator * r + 3.64784832476320460504;
    numerator = numerator * r + 5.7694972214606914055;
    numerator = numerator * r + 4.6303378461565452959;
    numerator = numerator * r + 1.42343711074968357734;
    let mut denominator = 1.05075007164441684324e-9;
    denominator = denominator * r + 5.475938084995344946e-4;
    denominator = denominator * r + 0.0151986665636164571966;
    denominator = denominator * r + 0.14810397642748007459;
    denominator = denominator * r + 0.68976733498510000455;
    denominator = denominator * r + 1.6763848301838038494;
    denominator = denominator * r + 2.05319162663775882187;
    denominator = denominator * r + 1.0;
    numerator / denominator
}

#[no_mangle]
pub unsafe extern "C" fn generate_risk_report(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(24..=MAX_INPUT_LENGTH).contains(&input_length) { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if values.iter().any(|value| !value.is_finite()) { return -1; }
    let portfolio = values[0];
    let confidence = values[1];
    let horizon = values[2];
    let count_value = values[3];
    if !(20.0..=64.0).contains(&count_value) || count_value.fract() != 0.0 { return -1; }
    let count = count_value as usize;
    if input_length != 4 + count || !(100.0..=1_000_000.0).contains(&portfolio) ||
        !(0.5..=0.95).contains(&confidence) || !(1.0..=10.0).contains(&horizon) { return -1; }
    let mut returns = [0.0_f64; 64];
    let mut sum = 0.0;
    for i in 0..count {
        let value = values[4 + i];
        if !(-0.25..=0.25).contains(&value) { return -1; }
        returns[i] = value;
        sum += value;
    }
    let mean = sum / count as f64;
    let mut squared_deviations = 0.0;
    for value in &returns[..count] {
        let difference = *value - mean;
        squared_deviations += difference * difference;
    }
    let sample_sd = (squared_deviations / (count - 1) as f64).sqrt();
    if sample_sd == 0.0 { return -1; }
    let tail_count = ((1.0 - confidence) * count as f64).floor() as usize;
    if tail_count < 1 { return -1; }
    returns[..count].sort_by(|a, b| a.total_cmp(b));
    let tail_sum: f64 = returns[..tail_count].iter().sum();
    let scale = horizon.sqrt();
    let z = qnorm(confidence);
    let es_multiplier = (-0.5 * z * z).exp() / (2.0 * PI).sqrt() / (1.0 - confidence);
    let mut third_moment = 0.0;
    let mut fourth_moment = 0.0;
    for value in &returns[..count] {
        let difference = *value - mean;
        let square = difference * difference;
        third_moment += square * difference;
        fourth_moment += square * square;
    }
    third_moment /= count as f64;
    fourth_moment /= count as f64;
    let result = [
        -returns[tail_count - 1] * portfolio * scale,
        -(tail_sum / tail_count as f64) * portfolio * scale,
        portfolio * (z * sample_sd - mean) * scale,
        portfolio * (es_multiplier * sample_sd - mean) * scale,
        mean,
        sample_sd,
        third_moment / (sample_sd * sample_sd * sample_sd),
        fourth_moment / (sample_sd * sample_sd * sample_sd * sample_sd) - 3.0,
    ];
    if output.is_null() || capacity < result.len() { return -2; }
    std::ptr::copy_nonoverlapping(result.as_ptr(), output, result.len());
    result.len() as i64
}
