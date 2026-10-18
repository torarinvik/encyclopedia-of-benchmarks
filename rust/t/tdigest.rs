const MAX_SAMPLES: usize = 32;
const MAX_QUERIES: usize = 4;
const MAX_INPUT_LENGTH: usize = 45;
const MAX_VALID_INPUT_LENGTH: usize = 44;
const MAX_CENTROIDS: usize = 44;
const MAX_OUTPUT_LENGTH: usize = 10;
const TWO_PI: f64 = 6.283185307179586476925286766559;

fn integer_in_range(value: f64, low: i32, high: i32) -> bool {
    value.is_finite() && value >= low as f64 && value <= high as f64 && value.fract() == 0.0
}

fn interpolate(x0: f64, y0: f64, x1: f64, y1: f64, x: f64) -> f64 {
    if x1 <= x0 { return y1; }
    y0 + (x - x0) / (x1 - x0) * (y1 - y0)
}

fn quantile_limit(compression: f64, mut q: f64) -> f64 {
    if q < 0.0 { q = 0.0; }
    if q > 1.0 { q = 1.0; }
    let k = compression / TWO_PI * (2.0 * q - 1.0).asin() + 1.0;
    let angle = k * TWO_PI / compression;
    if angle >= 1.57079632679489661923 { return 1.0; }
    if angle <= -1.57079632679489661923 { return 0.0; }
    (angle.sin() + 1.0) / 2.0
}

fn quantile(q: f64, means: &[f64; MAX_CENTROIDS], weights: &[f64; MAX_CENTROIDS],
            centroid_count: usize, total_weight: f64, minimum: f64, maximum: f64) -> f64 {
    if centroid_count == 1 { return means[0]; }
    let index = q * total_weight;
    if index <= 0.0 { return minimum; }
    if index >= total_weight { return maximum; }
    let mut previous_value = minimum;
    let mut previous_index = 0.0;
    let mut current_index = 0.0;
    for i in 0..centroid_count {
        current_index += if i == 0 { weights[i] / 2.0 } else { (weights[i - 1] + weights[i]) / 2.0 };
        if index < current_index {
            return interpolate(previous_index, previous_value, current_index, means[i], index);
        }
        previous_value = means[i];
        previous_index = current_index;
    }
    interpolate(previous_index, previous_value, total_weight, maximum, index)
}

fn cdf(value: f64, means: &[f64; MAX_CENTROIDS], weights: &[f64; MAX_CENTROIDS],
       centroid_count: usize, total_weight: f64, minimum: f64, maximum: f64) -> f64 {
    if value < minimum { return 0.0; }
    if value > maximum { return 1.0; }
    if maximum <= minimum { return 0.5; }
    let mut previous_value = minimum;
    let mut previous_index = 0.0;
    let mut current_index = 0.0;
    for i in 0..centroid_count {
        current_index += if i == 0 { weights[i] / 2.0 } else { (weights[i - 1] + weights[i]) / 2.0 };
        if value < means[i] {
            return interpolate(previous_value, previous_index, means[i], current_index, value) / total_weight;
        }
        previous_value = means[i];
        previous_index = current_index;
    }
    interpolate(previous_value, previous_index, maximum, total_weight, value) / total_weight
}

#[no_mangle]
pub unsafe extern "C" fn tdigest(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 7 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|value| !value.is_finite()) { return -1; }
    if !integer_in_range(values[0], 10, 20) || !integer_in_range(values[1], 1, MAX_SAMPLES as i32) { return -1; }
    let sample_count = values[1] as usize;
    let q_count_index = 2 + sample_count;
    if q_count_index >= input_length || !integer_in_range(values[q_count_index], 1, MAX_QUERIES as i32) { return -1; }
    let q_count = values[q_count_index] as usize;
    let q_start = q_count_index + 1;
    let cdf_count_index = q_start + q_count;
    if cdf_count_index >= input_length || !integer_in_range(values[cdf_count_index], 1, MAX_QUERIES as i32) { return -1; }
    let cdf_count = values[cdf_count_index] as usize;
    let cdf_start = cdf_count_index + 1;
    if input_length != cdf_start + cdf_count || input_length > MAX_VALID_INPUT_LENGTH { return -1; }

    let mut sorted = [0.0; MAX_SAMPLES];
    let mut probabilities = [0.0; MAX_QUERIES];
    let mut cdf_values = [0.0; MAX_QUERIES];
    for i in 0..sample_count {
        let value = values[2 + i];
        if !integer_in_range(value, -8, 8) { return -1; }
        sorted[i] = value;
    }
    for i in 0..q_count {
        let q = values[q_start + i];
        if !(0.0..=1.0).contains(&q) || (q * 4.0).fract() != 0.0 { return -1; }
        probabilities[i] = q;
    }
    for i in 0..cdf_count {
        let value = values[cdf_start + i];
        if !integer_in_range(value, -8, 8) { return -1; }
        cdf_values[i] = value;
    }
    for i in 1..sample_count {
        let value = sorted[i];
        let mut j = i;
        while j > 0 && sorted[j - 1] > value {
            sorted[j] = sorted[j - 1];
            j -= 1;
        }
        sorted[j] = value;
    }

    let compression = values[0];
    let total_weight = sample_count as f64;
    let centroid_capacity = 2 * (compression as usize + 2);
    let mut means = [0.0; MAX_CENTROIDS];
    let mut weights = [0.0; MAX_CENTROIDS];
    let mut last = 0usize;
    means[0] = sorted[0];
    weights[0] = 1.0;
    let mut closed_weight = 0.0;
    let mut weight_limit = total_weight * quantile_limit(compression, 0.0);
    for i in 1..sample_count {
        let projected = weights[last] + 1.0;
        let room_left = closed_weight + projected <= weight_limit;
        if room_left || last == centroid_capacity - 1 {
            weights[last] = projected;
            means[last] += (sorted[i] - means[last]) / projected;
        } else {
            closed_weight += weights[last];
            weight_limit = total_weight * quantile_limit(compression, closed_weight / total_weight);
            last += 1;
            means[last] = sorted[i];
            weights[last] = 1.0;
        }
    }
    let centroid_count = last + 1;
    let minimum = sorted[0];
    let maximum = sorted[sample_count - 1];
    let mut staged = [0.0; MAX_OUTPUT_LENGTH];
    staged[0] = q_count as f64;
    for i in 0..q_count {
        staged[1 + i] = quantile(probabilities[i], &means, &weights, centroid_count, total_weight, minimum, maximum);
    }
    staged[1 + q_count] = cdf_count as f64;
    for i in 0..cdf_count {
        staged[2 + q_count + i] = cdf(cdf_values[i], &means, &weights, centroid_count, total_weight, minimum, maximum);
    }
    let result_length = q_count + cdf_count + 2;
    if output.is_null() || output_capacity < result_length { return -2; }
    for i in 0..result_length {
        unsafe { *output.add(i) = staged[i]; }
    }
    result_length as i64
}
