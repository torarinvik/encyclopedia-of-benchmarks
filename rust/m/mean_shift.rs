const MAX_POINTS: usize = 16;
const MAX_DIMENSION: usize = 3;
const MAX_INPUT_LENGTH: usize = 54;
const MARGIN: f64 = 1.0e-6;

fn distance(a: &[f64], a_start: usize, b: &[f64], b_start: usize, dimensions: usize) -> f64 {
    let mut sum = 0.0;
    for d in 0..dimensions { let difference = a[a_start + d] - b[b_start + d]; sum += difference * difference; }
    sum.powf(0.5)
}
fn near(value: f64, threshold: f64) -> bool { (value - threshold).abs() < MARGIN }

#[no_mangle]
pub unsafe extern "C" fn mean_shift(input: *const f64, length: usize, output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values.iter().any(|x| !x.is_finite()) { return -1; }
    let (n_value, d_value, bandwidth, iter_value, tolerance) = (values[0], values[1], values[2], values[3], values[4]);
    if n_value.trunc() != n_value || d_value.trunc() != d_value || iter_value.trunc() != iter_value { return -1; }
    if n_value < 1.0 || n_value > MAX_POINTS as f64 || d_value < 1.0 || d_value > MAX_DIMENSION as f64 ||
       iter_value < 1.0 || iter_value > 64.0 || bandwidth < 0.5 || bandwidth > 20.0 || tolerance < 1.0e-5 || tolerance > 1.0e-2 { return -1; }
    let n = n_value as usize; let dimensions = d_value as usize; let max_iterations = iter_value as usize;
    if length != 5 + n * dimensions { return -1; }
    let data = &values[5..];
    if data.iter().any(|x| *x < -10.0 || *x > 10.0) { return -1; }
    let mut candidates = [0.0f64; MAX_POINTS * MAX_DIMENSION];
    let mut next = [0.0f64; MAX_POINTS * MAX_DIMENSION];
    candidates[..data.len()].copy_from_slice(data);
    for _ in 0..max_iterations {
        for c in 0..n {
            let mut sums = [0.0f64; MAX_DIMENSION]; let mut neighbors = 0usize;
            for p in 0..n {
                let dist = distance(data, p * dimensions, &candidates, c * dimensions, dimensions);
                if near(dist, bandwidth) { return -1; }
                if dist <= bandwidth {
                    neighbors += 1;
                    for d in 0..dimensions { sums[d] += data[p * dimensions + d]; }
                }
            }
            for d in 0..dimensions { next[c * dimensions + d] = if neighbors == 0 { candidates[c * dimensions + d] } else { sums[d] / neighbors as f64 }; }
        }
        let mut all_converged = true;
        for c in 0..n {
            let movement = distance(&candidates, c * dimensions, &next, c * dimensions, dimensions);
            if near(movement, tolerance) { return -1; }
            if movement >= tolerance { all_converged = false; break; }
        }
        if all_converged { break; }
        for i in 0..n * dimensions { candidates[i] = next[i]; }
    }
    let mut centroids = [0.0f64; MAX_POINTS * MAX_DIMENSION]; let mut centroid_count = 0usize;
    for c in 0..n {
        let mut keep = true;
        for existing in 0..centroid_count {
            let dist = distance(&candidates, c * dimensions, &centroids, existing * dimensions, dimensions);
            if near(dist, bandwidth) { return -1; }
            if dist < bandwidth { keep = false; break; }
        }
        if keep { for d in 0..dimensions { centroids[centroid_count * dimensions + d] = candidates[c * dimensions + d]; } centroid_count += 1; }
    }
    let mut labels = [0.0f64; MAX_POINTS];
    for p in 0..n {
        let mut best_index = 0usize;
        let mut best_distance = distance(data, p * dimensions, &centroids, 0, dimensions);
        for c in 1..centroid_count {
            let dist = distance(data, p * dimensions, &centroids, c * dimensions, dimensions);
            if dist != best_distance && near(dist, best_distance) { return -1; }
            if dist < best_distance { best_index = c; best_distance = dist; }
        }
        labels[p] = best_index as f64;
    }
    if output.is_null() || capacity < n { return -2; }
    for i in 0..n { *output.add(i) = labels[i]; }
    n as i64
}
