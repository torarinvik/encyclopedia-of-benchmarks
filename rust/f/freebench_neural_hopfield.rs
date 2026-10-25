const PATTERN_COUNT: usize = 10;
const MAX_NEURONS: usize = 8;

fn activation(value: f32) -> f32 {
    let x = f64::from(value).clamp(-200.0, 200.0);
    let e = (-x).exp();
    ((1.0 - e) / (1.0 + e)) as f32
}

fn run_cont(weights: &[f32], source: &[i64], dest: &mut [i64]) -> bool {
    let neurons = source.len();
    let mut temp_a = [0.0f32; MAX_NEURONS];
    let mut temp_c = [0i64; MAX_NEURONS];
    for neuron in 0..neurons {
        dest[neuron] = source[neuron];
        temp_a[neuron] = source[neuron] as f32;
    }
    let (mut stable, mut threshold) = (false, false);
    let mut iterations = 0;
    while !stable && iterations < 500 {
        let mut threshold_iterations = 0;
        for row in 0..neurons {
            let mut sum = 0.0f32;
            for neuron in 0..neurons { sum += weights[row * neurons + neuron] * source[neuron] as f32; }
            temp_a[row] = activation(sum);
        }
        while !threshold && threshold_iterations < 50 {
            threshold = true;
            for row in 0..neurons {
                if temp_a[row].abs() < 0.7 {
                    let mut sum = 0.0f32;
                    for neuron in 0..neurons { sum += weights[row * neurons + neuron] * temp_a[neuron]; }
                    temp_a[row] = activation(sum);
                    if temp_a[row] < 0.7 { threshold = false; }
                }
            }
            threshold_iterations += 1;
        }
        let mut same = true;
        for neuron in 0..neurons {
            temp_c[neuron] = if temp_a[neuron] > 0.0 { 1 } else { -1 };
            if dest[neuron] != temp_c[neuron] { same = false; }
        }
        if same { stable = true; }
        else {
            for neuron in 0..neurons {
                if dest[neuron] != temp_c[neuron] { dest[neuron] = temp_c[neuron]; break; }
            }
            for neuron in 0..neurons { temp_a[neuron] = dest[neuron] as f32; }
        }
        iterations += 1;
    }
    iterations < 500
}

#[no_mangle]
pub unsafe extern "C" fn freebench_neural_hopfield(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > 94 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (width, height, pattern_count) = (values[0], values[1], values[2]);
    if !(1..=8).contains(&width) || !(1..=8).contains(&height) || pattern_count != PATTERN_COUNT as i64 { return -1; }
    let neurons = (width * height) as usize;
    if !(2..=MAX_NEURONS).contains(&neurons) || length != 3 + PATTERN_COUNT * (1 + neurons) { return -1; }

    let mut patterns = [0i64; PATTERN_COUNT * MAX_NEURONS];
    let mut offset = 3;
    for pattern in 0..PATTERN_COUNT {
        let label = values[offset];
        offset += 1;
        if !(65..=90).contains(&label) { return -1; }
        for neuron in 0..neurons {
            let cell = values[offset];
            offset += 1;
            if cell != -1 && cell != 1 { return -1; }
            patterns[pattern * MAX_NEURONS + neuron] = cell;
            if pattern != 0 && cell != patterns[neuron] { return -1; }
        }
    }

    let mut hamming_warnings = 0;
    for first in 0..PATTERN_COUNT {
        for second in first + 1..PATTERN_COUNT {
            let (mut normal, mut complement) = (0, 0);
            for neuron in 0..neurons {
                if patterns[first * MAX_NEURONS + neuron] != patterns[second * MAX_NEURONS + neuron] { normal += 1; }
                if patterns[first * MAX_NEURONS + neuron] != -patterns[second * MAX_NEURONS + neuron] { complement += 1; }
            }
            if normal < 2 { hamming_warnings += 1; }
            if complement < 2 { hamming_warnings += 1; }
        }
    }
    let _ = hamming_warnings;

    let mut weights = [0.0f32; MAX_NEURONS * MAX_NEURONS];
    for pattern in 0..PATTERN_COUNT {
        for row in 0..neurons {
            for column in 0..neurons {
                if row == column { weights[row * neurons + column] = 0.0; }
                else { weights[row * neurons + column] += (patterns[pattern * MAX_NEURONS + row] * patterns[pattern * MAX_NEURONS + column]) as f32; }
            }
        }
    }

    let mut converged = false;
    for _pass in 0..1 {
        let mut status = true;
        for pattern in 0..PATTERN_COUNT {
            let base = pattern * MAX_NEURONS;
            let source = &patterns[base..base + neurons];
            let mut recalled = [0i64; MAX_NEURONS];
            if !run_cont(&weights[..neurons * neurons], source, &mut recalled[..neurons]) { return -2; }
            let mut correction = [0.0f32; MAX_NEURONS];
            for neuron in 0..neurons {
                correction[neuron] = (source[neuron] - recalled[neuron]) as f32 * 0.5;
                if correction[neuron] != 0.0 { status = false; }
            }
            for row in 0..neurons {
                for column in 0..neurons {
                    if row == column { weights[row * neurons + column] = 0.0; }
                    else { weights[row * neurons + column] += correction[row] * source[column] as f32; }
                }
            }
        }
        if status { converged = true; }
    }
    if !converged { return -2; }

    let mut stored_count = 0i64;
    for pattern in 0..PATTERN_COUNT {
        let base = pattern * MAX_NEURONS;
        let source = &patterns[base..base + neurons];
        let mut recalled = [0i64; MAX_NEURONS];
        if !run_cont(&weights[..neurons * neurons], source, &mut recalled[..neurons]) { return -2; }
        if source == &recalled[..neurons] { stored_count += 1; }
    }
    stored_count
}
