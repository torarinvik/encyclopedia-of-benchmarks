const MAX_SAMPLES: usize = 8;
const MAX_FEATURES: usize = 4;
const MAX_INPUT: usize = 35;
const MAX_OUTPUT: usize = 34;
const MAX_ITERATIONS: usize = 1000;
const TOLERANCE: f64 = 1e-10;
const MIN_NORM: f64 = 1e-10;

fn power_iteration(matrix: &[f64; 16], n: usize) -> Option<(f64, [f64; 4])> {
    let mut vector = [0.0; MAX_FEATURES];
    let mut previous = [0.0; MAX_FEATURES];
    let mut next = [0.0; MAX_FEATURES];
    for i in 0..n { vector[i] = 1.0; }
    let mut converged = false;
    for _ in 0..MAX_ITERATIONS {
        for i in 0..n { previous[i] = vector[i]; }
        for i in 0..n {
            next[i] = 0.0;
            for j in 0..n {
                let product = matrix[i*n+j] * vector[j];
                if !product.is_finite() { return None; }
                next[i] += product;
                if !next[i].is_finite() { return None; }
            }
        }
        let mut norm_squared = 0.0;
        for i in 0..n {
            let square = next[i] * next[i];
            if !square.is_finite() { return None; }
            norm_squared += square;
            if !norm_squared.is_finite() { return None; }
        }
        let norm = norm_squared.sqrt();
        if !norm.is_finite() || norm <= MIN_NORM { return None; }
        for i in 0..n {
            vector[i] = next[i] / norm;
            if !vector[i].is_finite() { return None; }
        }
        let mut difference = 0.0;
        for i in 0..n {
            let d = (vector[i] - previous[i]).abs();
            if !d.is_finite() { return None; }
            if d > difference { difference = d; }
        }
        if difference < TOLERANCE { converged = true; break; }
    }
    if !converged { return None; }

    let mut numerator = 0.0;
    for i in 0..n {
        let mut row_sum = 0.0;
        for j in 0..n {
            let product = matrix[i*n+j] * vector[j];
            if !product.is_finite() { return None; }
            row_sum += product;
            if !row_sum.is_finite() { return None; }
        }
        let term = row_sum * vector[i];
        if !term.is_finite() { return None; }
        numerator += term;
        if !numerator.is_finite() { return None; }
    }
    let mut denominator = 0.0;
    for i in 0..n {
        let square = vector[i] * vector[i];
        if !square.is_finite() { return None; }
        denominator += square;
        if !denominator.is_finite() { return None; }
    }
    if denominator == 0.0 { return None; }
    let eigenvalue = numerator / denominator;
    if !eigenvalue.is_finite() { return None; }
    Some((eigenvalue, vector))
}

#[no_mangle]
pub unsafe extern "C" fn principal_component_analysis(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=MAX_INPUT).contains(&input_length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|x| !x.is_finite()) { return -1; }
    let sv = values[0]; let fv = values[1]; let cv = values[2];
    if sv < 2.0 || sv > MAX_SAMPLES as f64 || sv.fract() != 0.0 ||
       fv < 2.0 || fv > MAX_FEATURES as f64 || fv.fract() != 0.0 { return -1; }
    let samples = sv as usize; let features = fv as usize;
    if cv < 1.0 || cv > features as f64 || cv.fract() != 0.0 { return -1; }
    let components = cv as usize;
    if input_length != 3 + samples * features { return -1; }
    let mut rows = [0.0; MAX_SAMPLES * MAX_FEATURES];
    for i in 0..samples*features {
        let x = values[3+i];
        if !(-100.0..=100.0).contains(&x) { return -1; }
        rows[i] = x;
    }
    let mut means = [0.0; MAX_FEATURES];
    for row in 0..samples { for col in 0..features {
        means[col] += rows[row*features+col];
        if !means[col].is_finite() { return -1; }
    }}
    for col in 0..features {
        means[col] /= samples as f64;
        if !means[col].is_finite() { return -1; }
    }
    let mut centered = [0.0; MAX_SAMPLES * MAX_FEATURES];
    for row in 0..samples { for col in 0..features {
        centered[row*features+col] = rows[row*features+col] - means[col];
        if !centered[row*features+col].is_finite() { return -1; }
    }}
    let mut matrix = [0.0; 16];
    for i in 0..features { for j in i..features {
        let mut covariance = 0.0;
        for row in 0..samples {
            let product = centered[row*features+i] * centered[row*features+j];
            if !product.is_finite() { return -1; }
            covariance += product;
            if !covariance.is_finite() { return -1; }
        }
        covariance /= samples as f64;
        if !covariance.is_finite() { return -1; }
        matrix[i*features+j] = covariance;
        matrix[j*features+i] = covariance;
    }}
    let mut vectors = [0.0; 16];
    for component in 0..components {
        let (eigenvalue, vector) = match power_iteration(&matrix, features) {
            Some(pair) => pair,
            None => return -1,
        };
        for i in 0..features { vectors[component*features+i] = vector[i]; }
        for i in 0..features { for j in 0..features {
            let term = eigenvalue * vector[i] * vector[j];
            if !term.is_finite() { return -1; }
            matrix[i*features+j] -= term;
            if !matrix[i*features+j].is_finite() { return -1; }
        }}
    }
    let mut staged = [0.0; MAX_OUTPUT];
    staged[0] = samples as f64; staged[1] = components as f64;
    let mut pos = 2;
    for row in 0..samples { for component in 0..components {
        let mut score = 0.0;
        for feature in 0..features {
            let product = vectors[component*features+feature] * centered[row*features+feature];
            if !product.is_finite() { return -1; }
            score += product;
            if !score.is_finite() { return -1; }
        }
        staged[pos] = score; pos += 1;
    }}
    if output.is_null() || output_capacity < pos { return -2; }
    for i in 0..pos { unsafe { *output.add(i) = staged[i]; } }
    pos as i64
}
