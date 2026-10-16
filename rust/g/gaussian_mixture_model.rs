const MAX_SAMPLES: usize = 16;
const MAX_INPUT_LENGTH: usize = 19;
const PI: f64 = 3.14159265358979323846264338327950288;

fn gaussian_mixture_pdf(value: f64, mean: f64, variance: f64) -> f64 {
    let difference = value - mean;
    (-(difference * difference) / (2.0 * variance)).exp() / (2.0 * PI * variance).sqrt()
}

#[no_mangle]
pub unsafe extern "C" fn gaussian_mixture_model(values: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let count_value = *values;
    let max_iterations_value = *values.add(1);
    let tolerance_micro = *values.add(2);
    if !(2..=MAX_SAMPLES as i64).contains(&count_value)
        || !(1..=20).contains(&max_iterations_value)
        || !(1..=1000).contains(&tolerance_micro)
        || length != 3 + count_value as usize { return -1; }
    let count = count_value as usize;
    let mut data = [0.0f64; MAX_SAMPLES];
    let mut previous_sample = -5001i64;
    for index in 0..count {
        let sample = *values.add(3 + index);
        if !(-5000..=5000).contains(&sample) || sample < previous_sample { return -1; }
        previous_sample = sample;
        data[index] = sample as f64 / 1000.0;
    }
    let required = count + 1;
    if output.is_null() || capacity < required { return -2; }

    let data_mean = data[..count].iter().sum::<f64>() / count as f64;
    let mut variance = 0.0;
    for value in &data[..count] {
        let difference = *value - data_mean;
        variance += difference * difference;
    }
    variance = variance / (count - 1) as f64 + 1e-6;
    let mut weights = [0.5f64, 0.5];
    let mut means = [data[0], data[count - 1]];
    let mut variances = [variance, variance];
    let mut responsibilities = [[0.0f64; MAX_SAMPLES]; 2];
    let tolerance = tolerance_micro as f64 / 1_000_000.0;
    let mut previous_likelihood = 0.0;
    let mut has_previous_likelihood = false;
    let mut iterations = 0usize;

    for iteration in 0..max_iterations_value as usize {
        let mut component_counts = [0.0f64; 2];
        for index in 0..count {
            let probability0 = weights[0] * gaussian_mixture_pdf(data[index], means[0], variances[0]);
            let probability1 = weights[1] * gaussian_mixture_pdf(data[index], means[1], variances[1]);
            let total = probability0 + probability1;
            if total == 0.0 || !total.is_finite() { return -1; }
            responsibilities[0][index] = probability0 / total;
            responsibilities[1][index] = probability1 / total;
            component_counts[0] += responsibilities[0][index];
            component_counts[1] += responsibilities[1][index];
        }
        if component_counts[0] <= 0.0 || component_counts[1] <= 0.0 { return -1; }
        for component in 0..2 {
            weights[component] = component_counts[component] / count as f64;
            let mut weighted_sum = 0.0;
            for index in 0..count { weighted_sum += responsibilities[component][index] * data[index]; }
            means[component] = weighted_sum / component_counts[component];
            let mut covariance = 0.0;
            for index in 0..count {
                let difference = data[index] - means[component];
                covariance += responsibilities[component][index] * difference * difference;
            }
            variances[component] = covariance / component_counts[component] + 1e-6;
        }
        let mut likelihood = 0.0;
        for value in &data[..count] {
            let density = weights[0] * gaussian_mixture_pdf(*value, means[0], variances[0])
                + weights[1] * gaussian_mixture_pdf(*value, means[1], variances[1]);
            likelihood += (density + 1e-12).ln();
        }
        iterations = iteration + 1;
        if has_previous_likelihood && (likelihood - previous_likelihood).abs() < tolerance { break; }
        previous_likelihood = likelihood;
        has_previous_likelihood = true;
    }
    *output = iterations as u8;
    for index in 0..count {
        let probability0 = weights[0] * gaussian_mixture_pdf(data[index], means[0], variances[0]);
        let probability1 = weights[1] * gaussian_mixture_pdf(data[index], means[1], variances[1]);
        *output.add(index + 1) = if probability0 >= probability1 { 0 } else { 1 };
    }
    required as i64
}
