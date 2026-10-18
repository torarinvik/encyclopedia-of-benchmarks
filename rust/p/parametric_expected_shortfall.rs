const MAX_PARSEABLE_INPUT_LENGTH: usize = 69;

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

    let mut r = (-(1.0 - confidence).ln()).sqrt() - 1.6;
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
pub unsafe extern "C" fn calculate_es_parametric(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || !(24..=MAX_PARSEABLE_INPUT_LENGTH).contains(&input_length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, input_length);
    if values.iter().any(|value| !value.is_finite()) {
        return -1;
    }

    let portfolio_value = values[0];
    let confidence_level = values[1];
    let time_horizon = values[2];
    let count_value = values[3];
    if !(20.0..=64.0).contains(&count_value) || count_value.fract() != 0.0 {
        return -1;
    }
    let return_count = count_value as usize;
    if input_length != 4 + return_count
        || !(100.0..=1_000_000.0).contains(&portfolio_value)
        || !(0.5..=0.95).contains(&confidence_level)
        || !(1.0..=10.0).contains(&time_horizon)
    {
        return -1;
    }

    let mut mean = 0.0;
    for value in &values[4..] {
        if !(-0.25..=0.25).contains(value) {
            return -1;
        }
        mean += value;
    }
    mean /= return_count as f64;
    let mut squared_deviations = 0.0;
    for value in &values[4..] {
        let difference = value - mean;
        squared_deviations += difference * difference;
    }
    let sample_sd = (squared_deviations / (return_count - 1) as f64).sqrt();
    let z = qnorm(confidence_level);
    let density = (-0.5 * z * z).exp() / (2.0 * std::f64::consts::PI).sqrt();
    let result = portfolio_value
        * (density / (1.0 - confidence_level) * sample_sd - mean)
        * time_horizon.sqrt();

    if output.is_null() || output_capacity < 1 {
        return -2;
    }
    output.write(result);
    1
}
